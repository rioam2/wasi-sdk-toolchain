cmake_minimum_required(VERSION 3.25)

# Exercises the path a package manager takes: unpack into a directory it owns,
# reusing a cached archive instead of re-downloading.
#
#   cmake -DREPO_DIR=<dir> -DWORK_DIR=<dir> -DVERSION=<n> -P acquire_destination.cmake

include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestAssert.cmake")
include("${REPO_DIR}/cmake/WasiSdkAcquire.cmake")

foreach(required IN ITEMS WORK_DIR VERSION)
  if(NOT DEFINED ${required})
    message(FATAL_ERROR "${required} is required")
  endif()
endforeach()

set(destination "${WORK_DIR}/package/wasi-sdk")
set(archive_dir "${WORK_DIR}/downloads")
file(REMOVE_RECURSE "${WORK_DIR}/package")

if(CMAKE_HOST_WIN32)
  set(host_exe ".exe")
else()
  set(host_exe "")
endif()

wasi_sdk_acquire(
  VERSION "${VERSION}"
  DESTINATION "${destination}"
  ARCHIVE_DIR "${archive_dir}"
  QUIET)

if(NOT EXISTS "${destination}/bin/clang${host_exe}")
  message(FATAL_ERROR "assertion failed: nothing unpacked into ${destination}")
endif()

# A lock or staging file left in the destination would be packaged along with
# the SDK, so the caller's directory must contain only the release.
file(GLOB leftovers "${WORK_DIR}/package/*")
foreach(entry IN LISTS leftovers)
  if(NOT entry STREQUAL destination)
    message(FATAL_ERROR "assertion failed: acquire left '${entry}' beside the destination")
  endif()
endforeach()

# clang++ reaches the real binary through a symlink chain; a copy that resolved
# links would both break layout assumptions and multiply the package size. The
# Windows release ships real executables instead, and NTFS symlinks need
# privileges CI does not have.
if(NOT CMAKE_HOST_WIN32 AND NOT IS_SYMLINK "${destination}/bin/clang++")
  message(FATAL_ERROR "assertion failed: bin/clang++ is no longer a symlink")
endif()

set(archive "${archive_dir}/wasi-sdk-${VERSION}.0-")
file(GLOB archives "${archive_dir}/*.tar.gz")
list(LENGTH archives archive_count)
if(NOT archive_count EQUAL 1)
  message(FATAL_ERROR "assertion failed: expected the archive to be kept for reuse")
endif()

# Second acquire into a fresh destination must reuse the archive rather than
# download again.
file(REMOVE_RECURSE "${WORK_DIR}/package")
list(GET archives 0 kept_archive)
file(TIMESTAMP "${kept_archive}" before "%s%f")

wasi_sdk_acquire(
  VERSION "${VERSION}"
  DESTINATION "${destination}"
  ARCHIVE_DIR "${archive_dir}"
  QUIET)

file(TIMESTAMP "${kept_archive}" after "%s%f")
expect_eq("${after}" "${before}" "cached archive was re-downloaded instead of reused")

if(NOT EXISTS "${destination}/bin/clang${host_exe}")
  message(FATAL_ERROR "assertion failed: reuse path did not unpack the SDK")
endif()

message(STATUS "acquire into a caller-owned destination OK")
