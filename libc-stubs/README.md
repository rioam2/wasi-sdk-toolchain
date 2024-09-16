## libc-stubs

This folder contains signatures that declare some libc functionality not present in upstream wasi-sdk-23
These stubs do not polyfill any of libc's intended behavior, and usage of any of these functions should not be expected to succeed until fully implemented upstream by wasi-libc.
The purpose of these stubs are to allow non-ported libraries and codebases to be compiled, even if they rely on these unimplemented libc features. Usage of them is to be expected to fail at runtime.
The need for these stubs is no more when `setjmp`, `longjmp` signals and exceptions receive proper support in wasi-libc.
