require 'uri'
require 'mahjong/hai'
require 'mahjong/haiarray'
require 'mahjong/yama'
require 'mahjong/hand'
require 'mahjong/mentsu'
require 'mahjong/agari'
require 'mahjong/mentsutable'

module Mahjong
    class Error < StandardError; end

    REACTION        = [ :ron, :kan, :pon, :chi ]

    # 端数切り上げ
    def self.round_up(val, base)
        (val + base - 1) / base * base
    end
end
