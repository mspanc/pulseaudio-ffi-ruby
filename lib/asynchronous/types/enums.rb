module PulseAudio
  module Asynchronous
    module Types
      module Enums
        extend FFI::Library

        ContextState = enum [ :unconnected,
                              :connecting,
                              :authorizing,
                              :setting_name,
                              :ready,
                              :failed,
                              :terminated ]        
                              
                              
        Format = enum [ :u8,
                        :alaw,
                        :ulaw,
                        :s16le,
                        :s16be,
                        :float32le,
                        :float32be,
                        :s32le,
                        :s32be,
                        :s24le,
                        :s24be,
                        :s24_32le,
                        :s24_32be,
                        :max,
                        :invalid ]
                      
        ChannelPosition = enum  [
                      :position_invalid,
                      :position_mono,
                      :position_front_left,
                      :position_front_right,
                      :position_front_center,
                      :position_rear_center,
                      :position_rear_left,
                      :position_rear_right,
                      :position_lfe,
                      :position_front_left_of_center,
                      :position_front_right_of_center,
                      :position_side_left,
                      :position_side_right,
                      :position_aux0,
                      :position_aux1,
                      :position_aux2,
                      :position_aux3,
                      :position_aux4,
                      :position_aux5,
                      :position_aux6,
                      :position_aux7,
                      :position_aux8,
                      :position_aux9,
                      :position_aux10,
                      :position_aux11,
                      :position_aux12,
                      :position_aux13,
                      :position_aux14,
                      :position_aux15,
                      :position_aux16,
                      :position_aux17,
                      :position_aux18,
                      :position_aux19,
                      :position_aux20,
                      :position_aux21,
                      :position_aux22,
                      :position_aux23,
                      :position_aux24,
                      :position_aux25,
                      :position_aux26,
                      :position_aux27,
                      :position_aux28,
                      :position_aux29,
                      :position_aux30,
                      :position_aux31,
                      :position_top_center,
                      :position_top_front_left,
                      :position_top_front_right,
                      :position_top_front_center,
                      :position_top_rear_left,
                      :position_top_rear_right,
                      :position_top_rear_center,
                      :position_max ]    




        OperationState = enum [ :running,
                                :done,
                                :cancelled ]
                                
        SinkFlags = enum [ :noflags,
                           :hw_volume_ctrl,
                           :latency,
                           :hardware,
                           :network,
                           :hw_mute_ctrl,
                           :decibel_volume,
                           :flat_volume,
                           :dynamic_latency ]
                           
        SinkState = enum [ :invalid,
                           :running,
                           :idle,
                           :suspended ]
      end
    end
  end
end    
