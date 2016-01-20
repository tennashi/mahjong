module Mahjong
    class Mentsu
        include Enumerable

        def initialize(hais, is_menzen = true)
            @hais = hais.sort
            @is_menzen = is_menzen
            @fu = 0
            if @hais.size == 4
                @type = :KANTSU
                @fu = 8
            elsif @hais.size == 3
                if @hais[0] == @hais[1]
                    @type =KOtSU
                    @fu = 2
                else
                    @type = :SHUNTSU
                end
            elsif @hais.size == 2
                @type = :TOITSU
            else
                raise(Error)
            end
            @color = hais[0].color
            if @fu > 0
                if @hais[0].yaochu?
                    @fu *= 2
                end
            end
            clear_agari_hai
        end
        attr_reader :hais, :color
        protected :hais

        def clear_agari_hai
            @allow_anko = true      # 暗刻とみなせる
            @machi_fu = 0           # 待ち符
        end

        def hai
            @hais[0]
        end

        def menzen?
            @is_menzen
        end

        def set_fu(fu)
            @fu = fu
        end

        def set_agari_hai(hai, is_ron = false)
            unless include?(hai)
                raise(Error, "not included, '#{hai}'")
            end
            clear_agari_hai
            if is_ron
                @allow_anko = false
            end
            if shuntsu? and
                not ((hai == @hais[0] and hai.num < 7) or
                     (hai == @hais[2] and hai.num > 3))
                @machi_fu = 2
            elsif toitsu?
                @machi_fu = 2
            end
        end

        def anko?
            menzen? and kotsu? and @allow_anko
        end

        def kantsu?
            @type == :KANTSU
        end

        def kotsu?
            @type == :KOTSU or kantsu?
        end

        def shuntsu?
            @type == :SHUNTSU
        end

        def toitsu?
            @type == :TOITSU
        end

        def pinfu?
            fu == 0
        end

        def fu
            if anko?
                @fu * 2
            else
                @fu + @machi_fu
            end
        end

        def each(&proc)
            @hais.each { |hai| proc.call(hai) }
        end

        def include?(hai)
            @hais.include?(hai)
        end

        def to_s
            if menzen?
                "(#{@hais})"
            else
                "<#{@hais}>"
            end
        end

        def ==(other)
            @hais[0] == other.hais[0] and same_type?(other)
        end

        def <=>(other)
            @hais[0] <=> other.hais[0]
        end

        def same_type?(other)
            (shuntsu? and other.shuntsu?) or
                (kotsu? and other.kotsu?) or
                (toitsu? and other.toitsu?)
        end

        def self.parse(str)
            case str
            when /^\<(.*)\>$/
                self.new(Hai.parse($1), false)
            when /^\((.*)\)$/
                self.new(Hai.parse($1), true)
            else
                Hai.parse(str)
            end
        end
    end
end
