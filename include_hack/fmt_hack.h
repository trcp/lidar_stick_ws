#pragma once
#include <memory>
#include <fmt/format.h>

namespace fmt {
  // Overload fmt::ptr to support std::shared_ptr directly
  template <typename T>
  inline const void* ptr(const std::shared_ptr<T>& p) {
    return p.get();
  }
}
