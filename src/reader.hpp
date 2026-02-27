#pragma once

#include <cstdint>
#include <fstream>
#include <string>

class Reader {
public:
  virtual ~Reader() = default;

  virtual void skip_header() = 0;
  virtual bool read_number(uint32_t &num) = 0;
  virtual void reset() = 0;
};

class BufReader : public Reader {
  std::ifstream file;
  char buffer[1024 * 1024];
  char *ptr = buffer;
  char *end = ptr;

public:
  BufReader(std::string file);

  void skip_header() override;
  bool read_number(uint32_t &num) override;
  void reset() override;
};

class MMapReader : public Reader {
  int fd;
  char *address;
  size_t length;
  const char *ptr;
  const char *end;

public:
  MMapReader(std::string file);
  ~MMapReader() override;

  void skip_header() override;
  bool read_number(uint32_t &num) override;
  void reset() override;
};
