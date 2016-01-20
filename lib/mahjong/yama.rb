module Mahjong
    class Yama < HaiArray
        WANPAI = 14

        def initialize
            super()
            [ 'm', 'p', 's' ].each { |type|
                (1 .. 9).each { |num|
                    hai = Hai["#{num.to_s}#{type}"]
                    4.times {
                        self << hai
                    }
                }
            }
            shuffle
        end
        attr_reader :rest

        # 洗牌
        def shuffle
            replace(sort_by { rand })
            @pt = 0
            @rest = self.size - WANPAI
        end

        # 一枚自摸る
        def tsumo
            hai = get_hai
            @rest -= 1
            hai
        end

        # ドラめくり
        def dora
            get_hai
        end

        # 配牌
        def haipai
            hais = HaiArray.new
            13.times { hais << tsumo }
            hais.sort!
            hais
        end

        def drop(num)
            @rest -= num
        end

        private

        def get_hai
            hai = self[@pt]
            unless hai
                raise(Error, 'yama over')
            end
            @pt += 1
            hai
        end
    end
end
