#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

class Reader {
public:
  virtual ~Reader() = default;

  virtual bool read_number(uint32_t &num) = 0;
  virtual void reset() = 0;
};

class BufReader : public Reader {
  int fd;
  size_t alignment = 4096;
  size_t len = 4096 * 1024 * 8;
  char *buffer;
  char *ptr;
  char *end;

  void skip_header();

public:
  BufReader(std::string file);
  ~BufReader() override;

  bool read_number(uint32_t &num) override;
  void reset() override;
};

class MMapReader : public Reader {
  int fd;
  char *address;
  size_t length;
  const char *ptr;
  const char *end;

  void skip_header();

public:
  MMapReader(std::string file);
  ~MMapReader() override;

  bool read_number(uint32_t &num) override;
  void reset() override;
};

class MockReader : public Reader {
  std::vector<uint32_t> nums;
  size_t index = 0;

public:
  MockReader(std::string file);

  bool read_number(uint32_t &num) override;
  void reset() override;
};

void benchmark_readers(const std::string &file);
