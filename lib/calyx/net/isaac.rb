module Calyx::Net
  # An implementation of an ISAAC cipher used to generate random numbers for packet interchange.
  class ISAAC
    # Initializes the ISAAC cipher with the given seed.
    def initialize(seed)
      @aa = 0
      @bb = 0
      @cc = 0
      @mm = []
      @randrsl = Array.new(256, 0)

      seed.each_with_index {|element, i|
        @randrsl[i] = element
      }

      randinit
      nil
    end

    # Gets the next random value.
    # If 256 cycles have occured, the results array is regenerated.
    def next_value
      if @randcnt == 0
        isaac
        @randcnt = 256
      end
      @randcnt -= 1
      @randrsl[@randcnt].int
    end
    
    private

    # Generates 256 new results.
    def isaac
      r = @randrsl
      aa = @aa
      @cc = @cc+1
      bb = (@bb + (@cc)) & 0xffffffff
      x = y = 0

      (0...256).step(4){|i|
        x = @mm[i  ]
        aa = ((aa ^ (aa << 13)) + @mm[(i   + 128) & 0xff])
        aa &= 0xffffffff
        @mm[i  ] = y = (@mm[(x >> 2) & 0xff] + aa + bb) & 0xffffffff
        r[i  ] = bb = (@mm[(y >> 10) & 0xff] + x) & 0xffffffff
        x = @mm[i+1]
        aa = ((aa ^ (0x03ffffff & (aa >> 6))) + @mm[(i+1+128) & 0xff])
        aa &= 0xffffffff
        @mm[i+1] = y = (@mm[(x >> 2) & 0xff] + aa + bb) & 0xffffffff
        r[i+1] = bb = (@mm[(y >> 10) & 0xff] + x) & 0xffffffff
        x = @mm[i+2]
        aa = ((aa ^ (aa << 2)) + @mm[(i+2 + 128) & 0xff])
        aa &= 0xffffffff
        @mm[i+2] = y = (@mm[(x >> 2) & 0xff] + aa + bb) & 0xffffffff
        r[i+2] = bb = (@mm[(y >> 10) & 0xff] + x) & 0xffffffff
        x = @mm[i+3]
        aa = ((aa ^ (0x0000ffff & (aa >> 16))) + @mm[(i+3 + 128) & 0xff])
        aa &= 0xffffffff
        @mm[i+3] = y = (@mm[(x >> 2) & 0xff] + aa + bb) & 0xffffffff
        r[i+3] = bb = (@mm[(y >> 10) & 0xff] + x) & 0xffffffff
      }

      @bb = bb
      @aa = aa
    end

    # Initializes the memory array.
    def randinit
      c = d = e = f = g = h = j = k = 0x9e3779b9
      r = @randrsl

      (1..4).each {
        c = c ^ (d << 11)
        f += c
        d += e
        d = d ^ (0x3fffffff & (e >> 2))
        g += d
        e += f
        e = e ^ (f << 8)
        h += e
        f += g
        f = f ^ (0x0000ffff & (g >> 16))
        j += f
        g += h
        g = g ^ (h << 10)
        k += g
        h += j
        h = h ^ (0x0fffffff & (j >> 4))
        c += h
        j += k
        j = j ^ (k << 8)
        d += j
        k += c
        k = k ^ (0x007fffff & (c >> 9))
        e += k
        c += d
      }

      (0...256).step(8){|i|
        c += r[i  ]
        d += r[i+1]
        e += r[i+2]
        f += r[i+3]
        g += r[i+4]
        h += r[i+5]
        j += r[i+6]
        k += r[i+7]
        c = c ^ (d << 11)
        f += c
        d += e
        d = d ^ (0x3fffffff & (e >> 2))
        g += d
        e += f
        e = e ^ (f << 8)
        h += e
        f += g
        f = f ^ (0x0000ffff & (g >> 16))
        j += f
        g += h
        g = g ^ (h << 10)
        k += g
        h += j
        h = h ^ (0x0fffffff & (j >> 4))
        c += h
        j += k
        j = j ^ (k << 8)
        d += j
        k += c
        k = k ^ (0x007fffff & (c >> 9))
        e += k
        c += d
        @mm[i  ] = c
        @mm[i+1] = d
        @mm[i+2] = e
        @mm[i+3] = f
        @mm[i+4] = g
        @mm[i+5] = h
        @mm[i+6] = j
        @mm[i+7] = k
      }

      (0...256).step(8){|i|
        c += @mm[i  ]
        d += @mm[i+1]
        e += @mm[i+2]
        f += @mm[i+3]
        g += @mm[i+4]
        h += @mm[i+5]
        j += @mm[i+6]
        k += @mm[i+7]
        c = c ^ (d << 11)
        f += c
        d += e
        d = d ^ (0x3fffffff & (e >> 2))
        g += d
        e += f
        e = e ^ (f << 8)
        h += e
        f += g
        f = f ^ (0x0000ffff & (g >> 16))
        j += f
        g += h
        g = g ^ (h << 10)
        k += g
        h += j
        h = h ^ (0x0fffffff & (j >> 4))
        c += h
        j += k
        j = j ^ (k << 8)
        d += j
        k += c
        k = k ^ (0x007fffff & (c >> 9))
        e += k
        c += d
        @mm[i  ] = c
        @mm[i+1] = d
        @mm[i+2] = e
        @mm[i+3] = f
        @mm[i+4] = g
        @mm[i+5] = h
        @mm[i+6] = j
        @mm[i+7] = k
      }

      isaac
      @randcnt = 256
    end
  end
end
