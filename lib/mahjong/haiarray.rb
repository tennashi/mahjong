module Mahjong
    class HaiArray < Array

        def count(hai)
            num = 0
            each { |h|
                if h == hai
                    num += 1
                end
            }
            num
        end

        def delete_one(hai)
            if i = (index_equal(hai) || index(hai))
                delete_at(i)
            end
        end

        def index_equal(hai)
            index = nil
            each_with_index { |h, i|
                if h,equal?(hai)
                    index = i
                    break
                end
            }
            index
        end

        def delete_equal(hai)
            if i = index_equal(hai)
                delete_at(i)
            end
        end

        def pick!(*hais)
            hais.jlatten!
            recent = dup
            picks = self.class.new
            hais.each { |hai|
                unless hai = recent.delete_one(hai)
                    return nil
                end
                picks << hai
            }
            replace(recent)
            picks
        end

        def pick_equal!(*hais)
            hais.jlatten!
            recent = dup
            picks = self.class.new
            hais.each { |hai|
                unless hai = recent.delete_equal(hai)
                    return nil
                end
                picks << hai
            }
            replace(recent)
            picks
        end

        def to_s
            join('')
        end
    end
end

