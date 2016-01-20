module Mahjong
    class Hai
        include Comparable

        COLOR_MANZU = 0
        COLOR_PINZU = 1
        COLOR_SOUZU = 2
        COLOR_ZIHAI = 3
        COLORS = [ 'm', 'p', 's', 'z' ]

        INSTANCE = Hash.new

        private_class_method :new

        def initialize(str)
            match = /^([1-9])([mpsz])$/i.match(str)
            unless match
                raise(Error, "illegal hai, '#{str}'")
            end
            @num = match[1].to_i
            color = match[2].dup
            @is_dora = !color.downcase!.nil?
            @color = COLORS.index(color)
            @str = str
        end
        attr_reader :num, :color

        # ドラ判定
        def dora?
            @is_dora
        end

        # 字牌判定
        def zihai?
            @color == COLOR_ZIHAI
        end

        # 么九牌判定
        def yaochu?
            zihai? or @num == 1 or @num == 9
        end

        # 三元牌判定
        def sangenpai?
            zihai? and @num > 4
        end

        # 役牌判定
        def yakuhai?(kaze)
            sangenpai? or kaze.include?(self)
        end

        def <=>(other)
            if other.nil?
                nil
            else
                unless other.is_a?(Hai)
                    raise(Error)
                end
                [ @color, @num ] <=> [other.color, other.num ]
            end
        end

        def *(num)
            hais = Array.new
            num.times { hais << self }
            hais
        end

        def succ
            case @color
            when COLOR_MANZU, COLOR_PINZU, COLOR_SOUZU
                num = (@num < 9) ? @num + 1 : 1
            when COLOR_ZIHAI
                if @num <= 4
                    num = (@num < 4) ? @num + 1 : 1
                else
                    num = (@num < 7) ? @num + 1 : 5
                end
            end
            self.class["#{num}#COLORS[@color]}"]
        end

        def -(num)
            self + (-num)
        end

        def to_s
            @str
        end

        def to_k
            if @color == COLOR_ZIHAI
                [ '東', '南', '西', '北', '白', '発', '中' ][@num - 1]
            else
                to_s
            end
        end

        def self.[](str)
            if str
                INSTANCE[str] ||= new(str)
            end
        end

        def self.parse(str)
            hais = HaiArray.new
            str.scan(/[1-9][mpsz]/i) { |hai|
                hais << self[hai]
            }
            hais
        end

        def self.each(&proc)
            4.times { |i|
                [ 9, 9, 9, 7 ][i].times { |j|
                    proc.call(self["#{j + 1}#{COLORS[i]}"])
                }
            }
        end
    end
end

