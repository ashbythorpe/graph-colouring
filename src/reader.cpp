#include "reader.hpp"
#include <charconv>
#include <cstdint>
#include <cstring>
#include <fcntl.h>
#include <fstream>
#include <iostream>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

bool isspace(char c) { return c == ' ' || c == '\n' || c == '\t' || c == '\r'; }

BufReader::BufReader(std::string file) : file(std::ifstream{file}) {}

void BufReader::skip_header() {
  std::string line;
  while (file.peek() == '#') {
    std::getline(file, line);
  }
}

bool BufReader::read_number(uint32_t &num) {
  if (ptr >= end || (end - ptr) < 32) {
    size_t leftover = end - ptr;
    if (leftover > 0) {
      std::memmove(buffer, ptr, leftover);
    }

    file.read(buffer + leftover, (1024 * 1024) - leftover);
    size_t bytes_read = file.gcount();

    ptr = buffer;
    end = buffer + leftover + bytes_read;

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
  file.clear();
  file.seekg(0);
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
  if (address == MAP_FAILED) {
    std::cerr << "Error mapping file";
    return;
  }

  ptr = address;
  end = address + length;
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
