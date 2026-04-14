#include "reader.hpp"
#include "utils.hpp"
#include <charconv>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <fcntl.h>
#include <fstream>
#include <iostream>
#include <ostream>
#include <string>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

bool isspace(char c) { return c == ' ' || c == '\n' || c == '\t' || c == '\r'; }

BufReader::BufReader(std::string file) {
  int fd = open(file.c_str(), O_RDONLY | O_DIRECT);
  if (fd == -1) {
    std::cerr << "Failed to open file";
    return;
  }

  if (posix_memalign((void **)(&buffer), alignment, len) != 0) {
    std::cerr << "Failed to allocate buffer";
    close(fd);
    return;
  }

  ptr = buffer;
  end = buffer;

  skip_header();
}

void BufReader::skip_header() {
  while (true) {
    if (ptr >= end) {
      ssize_t bytes_read = read(fd, buffer, len);
      if (bytes_read <= 0) {
        return;
      }

      ptr = buffer;
      end = buffer + bytes_read;
    }

    if (*ptr == '#') {
      char *next_newline = (char *)memchr(ptr, '\n', end - ptr);

      if (next_newline) {
        ptr = next_newline + 1;
      } else {
        ptr = end;
      }
    } else {
      return;
    }
  }
}

bool BufReader::read_number(uint32_t &num) {
  if (ptr >= end || (end - ptr) < 32) {
    size_t leftover = end - ptr;
    char *new_ptr;

    if (leftover == 0) {
      new_ptr = buffer;
    } else {
      new_ptr = buffer + 4096 - leftover;
    }

    if (leftover > 0) {
      std::memmove(new_ptr, ptr, leftover);
    }

    size_t bytes_read = read(fd, new_ptr + leftover, len - 4096);

    ptr = new_ptr;
    end = new_ptr + leftover + bytes_read;

    if (bytes_read == 0 && leftover == 0) {
      return false;
    }
  }

  while (ptr < end && isspace(*ptr)) {
    ptr++;
  }

  auto [new_ptr, err] = std::from_chars(ptr, end, num);

  if (err == std::errc()) {
    ptr = const_cast<char *>(new_ptr);
    return true;
  } else {
    return false;
  }
}

void BufReader::reset() {
  lseek(fd, 0, SEEK_SET);

  ptr = buffer;
  end = buffer;

  skip_header();
}

BufReader::~BufReader() {
  free(buffer);
  close(fd);
}

MMapReader::MMapReader(std::string file) {
  fd = open(file.c_str(), O_RDONLY);
  if (fd == -1) {
    std::cerr << "Error opening file";
    return;
  }

  struct stat sb;
  if (fstat(fd, &sb) == -1) {
    std::cerr << "Error getting file stats";
    return;
  }
  length = sb.st_size;

  address =
      static_cast<char *>(mmap(NULL, length, PROT_READ, MAP_PRIVATE, fd, 0));
  madvise(address, length, MADV_SEQUENTIAL | MADV_WILLNEED);
  if (address == MAP_FAILED) {
    std::cerr << "Error mapping file";
    return;
  }

  ptr = address;
  end = address + length;

  skip_header();
}

MMapReader::~MMapReader() {
  munmap(address, length);
  close(fd);
}

void MMapReader::skip_header() {
  while (ptr < end && *ptr == '#') {
    while (ptr < end && *ptr != '\n') {
      ptr++;
    }

    if (ptr < end) {
      ptr++;
    }
  }
}

void MMapReader::reset() {
  ptr = address;
  end = address + length;

  skip_header();
}

bool MMapReader::read_number(uint32_t &num) {
  while (ptr < end && isspace(*ptr)) {
    ptr++;
  }

  if (ptr >= end) {
    return false;
  }

  auto [next_ptr, err] = std::from_chars(ptr, end, num);
  if (err != std::errc{}) {
    std::cerr << "Error parsing number" << std::endl;
    return false;
  }

  ptr = next_ptr;

  return true;
}

MockReader::MockReader(std::string file) {
  MMapReader reader{file};

  uint32_t num;
  while (reader.read_number(num)) {
    nums.push_back(num);
  }
}

bool MockReader::read_number(uint32_t &num) {
  if (index < nums.size()) {
    num = nums[index];
    index++;


    return true;
  }

  return false;
}

void MockReader::reset() { index = 0; }

void benchmark_readers(std::string &file) {
  {
    auto result = benchmark([&] {
      std::ifstream stream{file};

      uint32_t num;
      while (stream >> num) {
      }
    });

    std::cout << "Naive method\n";
    report_benchmark(result);
  }

  {
    auto result = benchmark([&] {
      BufReader reader{file};

      uint32_t num;
      while (reader.read_number(num)) {
      }
    });

    std::cout << "\nBuffered reader\n";
    report_benchmark(result);
  }

  {
    auto result = benchmark([&] {
      MMapReader reader{file};

      uint32_t num;
      while (reader.read_number(num)) {
      }
    });

    std::cout << "\nMmap reader\n";
    report_benchmark(result);
  }
}
