module Mahjong
    class Hand

        def initialize(arg = nil)
            @menzen = HaiArray.new  # 手牌
            @fusehai = 13           # 伏せ牌の数
            @mentsu = Array.new     # 晒した面子
            @kawa = HaiArray.new    # 捨て牌
            @bakaze = nil           # 場風
            @zikaze = nil           # 自風
            @richi = nil            # 立直した巡目
            @is_tenpai = nil        # 聴牌フラグ
            @furiten = 0            # フリテンフラグ
            @is_pure = true         # 一巡目フラグ
            @is_ippatsu = false     # 一発フラグ
            @is_rinshan = false     # 嶺上開花フラグ
            @is_haitei = false      # 海底フラグ
            @tsumo_hai = nil        # 自摸牌

            case arg
            when HaiArray
                @menzen = arg.dup
                @fusehai = 0
            when String
                parse(arg)
            end
        end
        attr_reader :kawa, :fusehai

        def <<(hai)
            @is_tenpai = nil
            case hai
            when Hai
                @menzen << hai
            when HaiArray
                @menzen.concat(hai)
            when Mentsu
                @mentsu << hai
            else
                raise(Error, 'illegal append')
            end
        end

        def delete(hai)
            @is_tenpai = nil
            @menzen.delete_equal(hai)
        end

        def [](index)
            @menzen[index]
        end

        def size
            @menzen.size
        end

        # 自摸
        def tsumo(hai)
            @is_tenpai = nil
            @tsumo_hai = hai
            if hai
                sort!
                @menzen << hai
            else
                @fusehai += 1
            end
        end

        # 捨牌
        def sutehai(hai)
            clear_pure
            @kawa << hai
            hai = drop(hai)
            sort!
            unless richi?
                @furiten &= 2
            end
            if @tsumo_hai != hai and @kawa.uniq.any? { |hai| agari?(hai) }
                @furiten |= 2
            end
            hai
        end

        def drop(hai)
            if @fusehai == 0
                delete(hai)
            else
                @fusehai -= 1
                hai
            end
        end

        def push(hai)
            @is_tenpai = nil
            @menzen.push(hai)
        end

        def pop
            @is_tenpai = nil
            @menzen.pop
        end

        # 立直可否判定
        def can_richi?
            !richi? and menzen? and tenpai?
        end

        # 立直判定
        def richi?
            @richi
        end

        # 立直
        def richi
            if @richi
                raise(Error, "already reachi")
            end
            if @is_pure
                @richi = 0
            else
                @richi = @kawa.size + 1
            end
            @is_ippatsu = true
        end

        # フリテン牌の追加
        def append_furiten(hai)
            if @furiten == 0 and agari?(hai)
                @furiten = 1
            end
        end

        # 純粋な一巡目を解消
        def clear_pure
            @is_pure = false
            @is_ippatsu = false
            @is_rinshan = false
        end

        # 純粋な一巡目判定
        def pure?
            @is_pure
        end

        # 海底摸月判定
        def set_haitei
            @is_haitei = true
        end

        # 捨て牌に対してとれる行動を返す.
        def get_reaction(hai, can_chi = true)
            reaction = Array.new
            if can_ron?(hai)
                reaction << :ron
            end
            unless richi?
                num = @menzen.count(hai)
                if num >= 3
                    reaction << :kan
                end
                if num >= 2
                    reaction << :pon
                end
                if can_chi and !hai.zihai? and
                    ((@menzen.include?(hai + 1) and @menzen.include?(hai + 2)) or
                     (@menzen.include?(hai - 1) and @menzen.include?(hai + 1)) or
                     (@menzen.include?(hai - 2) and @menzen.include?(hai - 1)))
                    reaction << :chi
                end
            end
            reaction
        end

        # ロン判定
        def can_ron?(hai)
            if @furiten == 0
                @menzen.push(hai)
                agari = get_agari(hai, true)
                @menzen.pop
                agari and agari.han > 0
            end
        end

        # 暗槓
        def ankan(hai)
            if hais = @menzen.pick!(*(hai * 4))
                @is_rinshan = trueappend_mentsu(Mentsu.new(hais))
            end
        end

        # 鳴き
        def naki(hai, *args)
            if hais = @menzen.pick!(*args)
                if hais.size == 3
                    @is_rinshan = true
                end
                append_mentsu(Mentsu.new(hais << hai, false))
            end
        end

        def have_equal?(hai)
            @menzen.find { |h| h.equal?(hai) }
        end

        def have?(hai)
            have_equal?(hai) || @menzen.find { |h| h == hai }
        end

        def can_tedashi?(hai)
            @menzen[0 ... -1].find { |h| h.equal?(hai) }
        end

        def sort!
            @menzen.sort! { |a, b|
                [ a.color, a.num, a.dora? ? 1 : 0] <=>
                [ b.color, b.num, b.dora? ? 1 : 0]
            }
            self
        end

        # 門前判定
        def menzen?
            @mentsu.all? { |mentsu| mentsu.menzen? }
        end

        # 場風をセット
        def set_bakaze(hai)
            @bakaze = hai
        end

        # 自風をセット
        def set_zikaze(hai)
            @zikaze = hai
        end

        # 親判定
        def oya?
            @zikaze == Hai['1z']
        end

        def each(&proc)
            @menzen.each { |hai| proc.call(hai) }
            @mentsu.each { |mentsu| proc.call(mentsu) }
        end

        def each_menzen(&proc)
            @menzen.each { |hai| proc.call(hai) }
        end

        def each_mentsu(&proc)
            @mentsu.each { |mentsu| proc.call(hai) }
        end

        def each_hai(&proc)
            @menzen.each { |hai| proc.call(hai) }
            @mentsu.each { |mentsu| mentsu.each { |hai| proc.call(hai) }}
        end

        def count_dora(dora)
            num = 0
            each_hai { |hai|
                num += dora.count(hai)
                if hai.dora?
                    num += 1
                end
            }
            num
        end

        def to_s
            str = @menzen.to_s
            @mentsu.each { |mentsu| str << mentsu.to_s }
            str
        end

        # 聴牌判定
        def tenpai?
            if @is_tenpai.nil?
                check_tenpai
            end
            @is_tenpai
        end

        def parse(str)
            @mentsu.clear
            str = str.gsub(/\<.*?\>|\(.*?\)/) { |mentsu|
                @mentsu << Mentsu.parse(mentsu)
                ''
            }
            @menzen = Hai.parse(str)
            @fusehai = 0
        end

        # 聴牌確認
        def check_tenpai
            Hai.each { |hai|
                if agari?(hai)
                    @is_tenpai = true
                    break
                end
            }
        end

        # 和了判定
        def agari?(hai = nil)
            if hai
                @menzen.push(hai)
                is_agari = check_agari
                @menzen.pop
                is_agari
            else
                check_agari
            end
        end

        # 和了確認
        def check_agari
            if kokushi? or chitoi?
                return true
            end
            @menzen.uniq.any? { |hai|
                hais = @menzen.dup
                hais.pick!(hai, hai) and check_agari_mentsu(hais)
            }
        end

        # テーブルを用いて四面子できているか調べる.
        def check_agari_mentsu(hais)
            Hai::COLORS.each { |color|
                id = 0
                9.times { |i|
                    id += (5 ** i) * hais.count(Hai["#{i + 1}#{color}"])
                }
                if (color == Hai::COLORS[Hai::COLOR_ZIHAI]) ?
                    (MENTSU_TABLE[id] != 2) : !MENTSU_TABLE[id]
                    return false
                end
            }
            true
        end

        # 和了を返す
        # hai = 和了牌
        # is_ron = ロン判定
        def get_agari(hai, is_ron = false)
            unless check_agari
                return false
            end
            if kokushi?
                Agari.kokushi
            else
                max_agari = nil
                each_agari_mentsu { |mentsu|
                    mentsu.each { |m|
                        if m.menzen? and m.include?(hai)
                            m.set_agari_hai(hai, is_ron)
                            if agari = Agari.parse(mentsu, kaze, is_ron)
                                if !max_agari or agari > max_agari
                                    max_agari = agari
                                end
                            end
                            m.clear_agari_hai
                        end
                    }
                }
                if max_agari
                    if menzen? and !is_ron
                        max_agari << :TSUMO
                    end
                    if @richi
                        max_agari << (@richi == 0 ? :WRICHI : :RICHI)
                        if @is_ippatsu
                            max_agari << :IPPATSU
                        end
                    end
                    if @is_pure
                        if is_ron
                            max_agari << :RENHOU
                        elsif oya?
                            max_agari << :TENHOU
                        else
                            max_agari << :CHIHOU
                        end
                    end
                    if @is_haitei
                        max_agari << (is_ron ? :HOUTEI : :HAITEI)
                    end
                    if @is_rinshan
                        max_agari << :RINSHAN
                    end
                end
                max_agari
            end
        end

        # 国士判定
        def kokushi?
            if menzen?
                uniq = @menzen.uniq
                uni.size == 13 and uniq.all? { |hai| hai.yaochu? }
            end
        end

        # 七対子判定
        def chitoi?
            if menzen?
                uniq = @menzen.uniq
                uniq.size == 7 and uniq.all? { |hai| @menzen.count(hai) == 2}
            end
        end

        # 和了形を返す.
        def each_agari_mentsu(&proc)
            uniq = @menzen.uniq
            # 七対子か
            if chitoi?
                proc.call(uniq.collect { |hai| Mentsu.new(HaiArray[ hai, hai ]) })
            end
            uniq.each { |hai|
                hais = @menzen.dup
                if head = hais.pick!(hai, hai)
                    mentsu = @mentsu.dup
                    head = Mentsu.new(head)
                    if hai.yakuhai?(kaze)
                        head.set_fu(2)
                    end
                    mentsu.push(head)
                    hais.sort!
                    divide_mentsu(hais, mentsu, proc)
                end
            }
        end

        # 面子に分解
        def divide_mentsu(hais, mentsu, proc)
            if hais.empty?
                proc.call(mentsu)
            else
                hai = hais[0]
                _hais = hais.dup
                if m = _hais.pick!(*(hai * 3))
                    mentsu.push(Mentsu.new(m))
                    divide_mentsu(_hais, mentsu, proc)
                    mentsu.pop
                end
                _hais = hais.dup
                if !hai.zihai? and m = _hais.pick!(hai, hai + 1, hai + 2)
                    mentsu.push(Mentsu.new(m))
                    divide_mentsu(_hais, mentsu, proc)
                    mentsu.pop
                end
            end
        end

        def append_mentsu(mentsu)
            @mentsu << mentsu
            mentsu
        end
    end
end




