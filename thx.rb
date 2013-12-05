#!/usr/bin/env ruby
require 'ffi'
module PortAudio
  extend FFI::Library
  typedef :double, :pa_time
  NO_ERROR=0
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

class Thx
  FRAME_RATE=44100
  def initialize(seconds, &block)
    @seconds = seconds
    @block = block
  end

  def start
    check PortAudio.Pa_Initialize
    stream = FFI::MemoryPointer.new :pointer
    data = FFI::MemoryPointer.new :pointer
    check PortAudio.Pa_OpenDefaultStream(stream, 0, 1,
                                         PortAudio::SAMPLE_FORMAT_FLOAT32,
                                         FRAME_RATE, 1<<15, method(:callback), data)
    stream = stream.get_pointer 0
    check PortAudio.Pa_StartStream stream
    sleep @seconds
    check PortAudio.Pa_StopStream stream
    check PortAudio.Pa_CloseStream stream
    check PortAudio.Pa_Terminate
  end

  def self.start(seconds, &block)
    new(seconds, &block).start
  end

  private
  def check(error)
    raise PortAudio.Pa_GetErrorText(error) unless error == PortAudio::NO_ERROR
  end

  def callback(input, output, buffer_size, time_info, status_flags, data)
    time_info = PortAudio::PaStreamCallbackTimeInfo.new time_info
    output.write_array_of_float buffer_size.times.map { @block.call time_info }
  end
end

Thx.start 10 do |time|
  rand -1.0..1.0
end
