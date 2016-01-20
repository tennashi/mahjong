module Mahjong
    class Agari
        include Comparable

        YAKUMAN_TABLE = {
            :KOKUSHI        => [ 1, '国士無双' ],
            :TSUISO         => [ 1, '字一色' ],
            :SUANKO         => [ 1, '四暗刻' ],
            :SUKANTSU       => [ 1, '四槓子' ],
            :CHINROUTOU     => [ 1, '清老頭' ],
            :DAISANGEN      => [ 1, '大三元' ],
            :SHOSUSHI       => [ 1, '小四喜' ],
            :DAISUSHI       => [ 1, '大四喜' ],
            :TENHOU         => [ 1, '天和' ],
            :CHIHOU         => [ 1, '地和' ]
        }
        YAKU_TABLE = {
            :WRICHI         => [ 2, 0, 'ダブリー'],
            :RICHI          => [ 1, 0, '立直' ],
            :IPPATSU        => [ 1, 0, '一発' ],
            :CHINITSU       => [ 6, 5, '清一色' ],
            :HONITSU        => [ 3, 2, '混一色' ],
            :JUNCHAN        => [ 3, 2, '純チャン' ],
            :RYANPEIKOU     => [ 3, 0, '二盃口' ],
            :SANANKO        => [ 2, 2, '三暗刻' ],
            :SANKANTSU      => [ 2, 2, '三槓子' ],
            :HONROUTOU      => [ 2, 2, '混老頭' ],
            :TOITOI         => [ 2, 2, '対々和' ],
            :CHANTA         => [ 2, 1, 'チャンタ' ],
            :CHITOI         => [ 2, 0, '七対子' ],
            :SHOSANGEN      => [ 2, 2, '小三元' ],
            :TANYAO         => [ 1, 1, '断么九' ],
            :PINFU          => [ 1, 0, '平和' ],
            :IPEIKOU        => [ 1, 0, '一盃口' ],
            :YAKUHAI        => [ 1, 1, '役牌' ],
            :TSUMO          => [ 1, 0, '門前自摸' ],
            :DORA           => [ 1, 1, 'ドラ' ],
            :HAITEI         => [ 1, 1, '海底摸月' ],
            :HOUTEI         => [ 1, 1, '河底撈魚' ],
            :SANSHOKU       => [ 2, 1, '三色同順' ],
            :SANSHOKUDOUKOU => [ 2, 2, '三色同刻' ],
            :ITSU           => [ 2, 1, '一気通貫' ],
        }

        def initialize
            @yakuman = Hash.new(0)
            @yaku = Hash.new(0)
            @src_fu = 0             # 符(切り上げ前)
            @fu = 0                 # 符(切り上げ後)
            @han = 0                # 翻
            @is_menzen = true       # 門前フラグ
        end
        attr_reader :fu, :han, :src_fu

        def yakuman
            @yakuman.size
        end

        def yakuman?
            !@yakuman.empty?
        end

        def <<(yaku)
            if table = YAKUMAN_TABLE[yaku]
                @yakuman[yaku] += table[0]
            elsif table = YAKU_TABLE[yaku]
                han = table[@is_menzen ? 0 : 1]
                if han > 0
                    @yaku[yaku] += han
                    @han += han
                end
            end
            self
        end

        def include?(yaku)
            @yakuman.include?(yaku) or
                @yaku.include?(yaku)
        end

        def <=>(other)
            [ yakuman, @han, @fu ] <=> [ other.yaakuman, other.han, other.fu ]
        end

        def parse(mentsu, kaze, is_ron)
            @mentsu = mentsu.dup.freeze
            @is_menzen = @mentsu.all? { |mentsu| mentsu.menzen? }
            @is_ron = is_ron
            @kaze = kaze
            check_pinfu
            check_color
            check_anko
            check_kantsu
            check_yaochu
            check_ipeikou
            check_sangenpai
            check_sanshoku
            check_itsu
            if include?(:CHITOI)
                @fu = @src_fu = 25
            else
                @src_fu = 20
                @mentsu.each { |mentsu| @src_fu += mentsu.fu }
                if is_ron
                    if @is_menzen
                        @src_fu += 10
                    end
                else
                    unless include?(:PINFU)
                        @src_fu += 2
                    end
                end
                @fu = Mahjong.round_up(@src_fu, 10)
            end
        end
        attr_reader :mentsu

        def point
            p = if yakuman? or @han >= 13
                    8000
                elsif @han >= 11
                    6000
                elsif @han >= 8
                    4000
                elsif @han > 6
                    3000
                elsif @han >= 5 or (@han == 4 and @fu > 20)
                    2000
                else
                    @fu * (2 ** (@han + 2))
                end
            @is_ron ? p * 4 : p
        end

        def to_s
            if yakuman?
                buff = "0 #{@han}"
                @yakuman.each { |id, han|
                    buff << " #{URI.encode(YAKUMAN_TABLE[id][1])} #{han}"
                }
            else
                buff = "#{@src_fu} #{@han}"
                @yaku.each { |id, han|
                    buff << " #{URI.encode(YAKU_TABLE[id][2])} #{han}"
                }
            end
            buff
        end

        def to_a
            if yakuman?
                buff = [ 0, 0 ]
                @yakuman.each { |id, han|
                    buff << YAKUMAN_TABLE[id][1] << han
                }
            else
                buff = [ @src_fu, @han ]
                @yaku.each { |id, han|
                    buff << YAKU_TABLE[id][2] << han
                }
            end
            buff
        end

        def self.kokushi
            agari = new
            agari << :KOKUSHI
        end

        def self.parse(mentsu, kaze, is_ron)
            agari = new
            agari.parse(mentsu, kaze, is_ron)
            agari
        end

        private

        # 平和, 七対子, 対々和
        def check_pinfu
            base = nil
            is_pinfu = true
            @mentsu.each { |mentsu|
                unless mentsu.toitsu?
                    if base and !base.same_type?(mentsu)
                        return
                    end
                    base = mentsu
                end
                is_pinfu &&= mentsu.pinfu?
            }
            if base
                if base.shuntsu?
                    if is_pinfu
                        self << :PINFU
                    end
                elsif base.kotsu?
                    self << :TOITOI
                end
            else
                self << :CHITOI
            end
        end

        # 字一色, 清一色, 混一色
        def check_color
            colors = Array.new
            colors = @mentsu.colleck { |mentsu| mentsu.color }
            colors.uniq!
            if colors.size == 1
                if colors[0] == Hai::COLOR_ZIHAI
                    self << :TSUISO
                else
                    self << :CHINITSU
                end
            elsif colors.size == 2 and colors.include?(Hai::COLOR_ZIHAI)
                self << :HONITSU
            end
        end

        # 三暗刻, 四暗刻
        def check_anko
            anko = @mentsu.select { |mentsu| mentsu.anko? }
            if anko.size >= 4
                self << :SUANKO
            elsif anko.size == 3
                self << :SANANKO
            end
        end

        # 三槓子, 四槓子
        def check_kantsu
            kantsu = @mentsu.select { |mentsu| mentsu.kantsu? }
            if kantsu.size >= 4
                self << :SUKANTSU
            elsif kantsu.size == 3
                self << :SANKANTSU
            end
        end

        # 清老頭, 混老頭, 純チャン, チャンタ, 断么九
        def check_yaochu
            honrou = true
            chanta = true
            tanyao = true
            zihai = false
            @mentsu.each { |mentsu|
                yaochu = false
                mentsu.each { |hai|
                    if hai.yaochu?
                        if hai.zihai?
                            zihai = true
                        end
                        tanyao = false
                        yaochu = true
                    else
                        honrou = false
                    end
                }
                unless yaochu
                    chanta = false
                end
            }
            if honrou
                if zihai
                    self << :HONROUTOU
                else
                    self << :CHINROUTOU
                end
            elsif chanta
                if zihai
                    self << :CHANTA
                else
                    self << :JUNCHAN
                end
            elsif tanyao
                self << :TANYAO
            end
        end

        # 一盃口, 二盃口
        def check_ipeikou
            mentsu = @mentsu.dup
            p = 0
            while !mentsu.empty?
                m = mentsu.shift
                if m.shuntsu? and i = mentsu.index(m)
                    mentsu.delete_at(i)
                    p += 1
                end
            end
            if p = 1
                self << :IPEIKOU
            elsif p >= 2
                self << :RYANPEIKOU
            end
        end

        # 三色
        def check_sanshoku
            mentsus = @mentsu.sort
            while mentsus.size >= 3
                mentsu = mentsus.shift
                if mentsu.color != Mahjong::Hai::COLOR_MANZU
                    break
                end
                if mentsus.find { |m| (m.color == Mahjong::Hai::COLOR_PINZU and
                                       m.same_type?(mentsu) and
                                       m.hai.num == mentsu.hai.num) } and
                                       mentsus.find { |m| (m.color == Mahjong::Hai::COLOR_SOUZU and
                                                           m.same_type?(mentsu) and
                                                           m.hai.num == mentsu.hai.num) }
                                       if mentsu.shuntsu?
                                           self << :SANSHOKU
                                       elsif mentsu.kotsu?
                                           self << :SANSYOKUDOUKOU
                                       end
                                       break
                end
            end
        end

        # 一気通貫
        def check_itsu
            mentsus = @mentsu.sort
            while mentsus.size >= 3
                mentsu = mentsus.shift
                if mentsu.shuntsu? and
                    !mentsu.hai.zihai? and
                    mentsu.hai.num == 1 and
                    mentsus.find { |m| m.shuntsu? and m.hai == mentsu.hai + 3 } and
                    mentsus.find { |m| m.shuntsu? and m.hai == mentsu.hai + 6 }
                    self << :ITSU
                    break
                end
            end
        end

        # 大三元, 小三元, 大四喜, 小四喜, 役牌
        def check_sangenpai
            kazehai_num = 0
            sangenpai_num = 0
            @mentsu.each { |mentsu|
                if mentsu.hai.zihai?
                    if mentsu.hai.sangenpai?
                        if mentsu.kotsu?
                            self << :YAKUHAI
                            sangenpai_num += 3
                        else
                            sangenpai_num += 2
                        end
                    else
                        if mentsu.kotsu?
                            @kaze.each { |hai|
                                if hai == mentsu.hai
                                    self << :YAKUHAI
                                end
                            }
                            kazehai_num += 3
                        else
                            kazehai_num += 2
                        end
                    end
                end
            }
            if sangenpai_num == 9
                self << :DAISANGEN
            elsif sangenpai_num == 8
                self << :SHOSANGEN
            end
            if kazehai_num == 11
                self << :SHOSUSHI
            elsif kazehai_num == 12
                self << :DAISUSHI
            end
        end
    end
end
