#!/usr/bin/env ruby
require 'ffi'
module PortAudio
  extend FFI::Library
  ffi_lib 'portaudio'
  attach_function :Pa_Initialize, [], :int
  attach_function :Pa_Terminate, [], :int

  StreamCallback = callback [:pointer, :pointer, :ulong, :int, :int, :pointer], :int
  attach_function :Pa_OpenDefaultStream, [:pointer, :int, :int, :int, :double, :ulong, StreamCallback, :pointer ], :int
  attach_function :Pa_StartStream, [:pointer], :int
  attach_function :Pa_StopStream, [:pointer], :int
  attach_function :Pa_CloseStream, [:pointer], :int
  attach_function :Pa_GetErrorText, [:int], :string
end
data = FFI::MemoryPointer.new :pointer
stream = FFI::MemoryPointer.new :pointer
FRAME_RATE=44100
PA_NO_ERROR=0
check = lambda {|error| raise PortAudio.Pa_GetErrorText(error) unless error == PA_NO_ERROR }
check[PortAudio.Pa_Initialize]
callback = ->(input, output, buffer_size, time_info, status_flags, data) {
  puts :hai
}
check[PortAudio.Pa_OpenDefaultStream(stream, 0, 1, 1, FRAME_RATE, 1<<4, callback, data)]
stream = stream.get_pointer 0
check[PortAudio.Pa_StartStream(stream)]
sleep 2
check[PortAudio.Pa_StopStream(stream)]
check[PortAudio.Pa_CloseStream(stream)]
check[PortAudio.Pa_Terminate]
