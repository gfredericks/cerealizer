require 'set'

def n_to_ternary(n)
  return "" if n==1
  n-=1
  digits = 1
  possible = 3
  while(n > possible)
    n -= possible
    possible *=3
    digits += 1
  end
  s = (n-1).to_s(3)
  "%0#{digits}d" % ((n-1).to_s(3).to_i)
end

def binary_to_n(s)
  ("1"+s).to_i(2)
end

def ternary_to_a(s)
  s.split_twos.map{|x|binary_to_n(x)}
end

class String
  def split_twos
    i = self.index('2')
    return [self] unless i
    [self[0...i]] + (self[(i+1)..-1]).split_twos
  end
end

def n_to_a(n)
  ternary_to_a(n_to_ternary(n))
end

def a_to_ternary(a)
  a.map{|x|x.to_s(2)[1..-1]}.join("2")
end

def ternary_to_n(s)
  possible = 1
  digits = 0
  n = 1
  until(digits == s.length)
    n += possible
    digits += 1
    possible *= 3
  end
  n + s.to_i(3)
end

def a_to_n(a)
  ternary_to_n(a_to_ternary(a))
end

def a_to_set(a)
  s = Set.new
  n = 0
  a.each do |m|
    s.add(n+=m)
  end
  s
end

def set_to_a(s)
  a = s.to_a.sort
  i = a.length-1
  while(i > 0)
    a[i] = a[i] - a[i-1]
    i-=1
  end
  a
end

def n_to_set(n)
  a_to_set(n_to_a n)
end

def set_to_n(s)
  a_to_n(set_to_a(s))
end
