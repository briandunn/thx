#!/usr/bin/env ruby
require 'ffi'
module PortAudio
  extend FFI::Library
  typedef :double, :pa_time
  class PaStreamCallbackTimeInfo < FFI::Struct
    layout :inputBufferAdcTime, :pa_time,
           :currentTime, :pa_time,
           :outputBufferDacTime, :pa_time
  end
  ffi_lib 'portaudio'
  attach_function :Pa_Initialize, [], :int
  attach_function :Pa_Terminate, [], :int
  SAMPLE_FORMAT_FLOAT32 = 1


  StreamCallback = callback [:pointer, :pointer, :ulong, :pointer, :ulong, :pointer], :int
  attach_function :Pa_OpenDefaultStream, [:pointer, :int, :int, :ulong, :double, :ulong, StreamCallback, :pointer ], :int
  attach_function :Pa_StartStream, [:pointer], :int
  attach_function :Pa_StopStream, [:pointer], :int
  attach_function :Pa_CloseStream, [:pointer], :int
  attach_function :Pa_GetErrorText, [:int], :string
end
data = FFI::MemoryPointer.new :pointer
stream = FFI::MemoryPointer.new :pointer
FRAME_RATE=44100
# FRAME_RATE=22050
PA_NO_ERROR=0
check = lambda {|error| raise PortAudio.Pa_GetErrorText(error) unless error == PA_NO_ERROR }
check[PortAudio.Pa_Initialize]


Callback = ->(input, output, buffer_size, time_info, status_flags, data) do
  # time_info = PortAudio::PaStreamCallbackTimeInfo.new(time_info)
  output.write_array_of_float buffer_size.times.map { rand -1.0..1.0 }
end

check[PortAudio.Pa_OpenDefaultStream(stream, 0, 1, PortAudio::SAMPLE_FORMAT_FLOAT32, FRAME_RATE, 1<<17, Callback, data)]
stream = stream.get_pointer 0
check[PortAudio.Pa_StartStream(stream)]
sleep 10
puts :stopping
check[PortAudio.Pa_StopStream(stream)]
puts :stopped
puts :closing
check[PortAudio.Pa_CloseStream(stream)]
puts :closed
puts :terminating
check[PortAudio.Pa_Terminate]
puts :terminated
