#pragma once

#include <ozz/base/io/stream.h>
#include <string.h>

// Macros
#define OZZAPI extern "C"

// Helpers
namespace ozz {
namespace io {

class DirectMemoryStream : public Stream {
public:
    DirectMemoryStream(const uint8_t* _data, size_t _dataSize)
        : data(_data)
        , dataSize(_dataSize) {
    }

    virtual ~DirectMemoryStream() {
    }

    bool opened() const {
        return true;
    }

    size_t Read(void* _buffer, size_t _size) {
        if (position + _size > dataSize) {
            return 0;
        }
        memcpy(_buffer, data + position, _size);
        position += _size;
        return _size;
    }
    size_t Write(const void* _buffer, size_t _size) {
        _buffer;
        _size;
        return 0;
    }
    int Seek(int _offset, Origin _origin) {
        int64_t newPosition = -1;
        switch (_origin) {
            case Stream::kCurrent:
                newPosition = ((int64_t)position + (int64_t)_offset);
                break;
            case Stream::kEnd:
                newPosition = ((int64_t)position - (int64_t)_offset);
                break;
            case Stream::kSet:
                newPosition = (int64_t)_offset;
                break;
        }
        if (newPosition < 0 || newPosition >= (int64_t)dataSize) {
            return 1;
        }
        position = (size_t)newPosition;
        return 0;
    }

    int Tell() const {
        return (int)position;
    }

    size_t Size() const {
        return dataSize;
    }

protected:
    const uint8_t* data = nullptr;
    size_t dataSize = 0;
    size_t position = 0;
};

} // namespace io
} // namespace ozz