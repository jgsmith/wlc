#!/usr/local/bin/ruby
require "test/unit"
require "lua"

class TC_Lua < Test::Unit::TestCase
  def lua_eval(code, setkey = nil, setvalue = nil)
    lua = Lua.new
    if setkey
      lua.set(setkey,setvalue)
    end
    lua.eval(code)
    lua.get('result')
  end

  def test_get_nil
    assert_equal(nil, lua_eval("result = nil"))
  end
  
  def test_get_boolean
    assert_equal(true, lua_eval("result = true"))
    assert_equal(false, lua_eval("result = false"))
  end

  def test_get_number
    assert_equal(3, lua_eval("result = 1 + 2"))
    assert_equal(30000, lua_eval("result = 10000 + 20000"))
    assert_equal(300000, lua_eval("result = 100000 + 200000"))
    assert_equal(1073741824, lua_eval("result = 1073741823 + 1"))
    assert_equal(0.1 + 0.1, lua_eval("result = 0.1 + 0.1"))
  end

  def test_get_string
    assert_equal("123", lua_eval('result = "123"') )
    assert_equal("123456", lua_eval('a = "123"; b="456"; result = a .. b') )
    assert_equal("ABC", lua_eval('result = string.char(65, 66, 67)') )
    assert_equal("FOO", lua_eval('result = string.upper("foo")') )
  end

  def test_get_table
    assert_equal({"string"=>"string", "number" => 123}, lua_eval('result = { ["string"] = "string"; ["number"] = 123 }'))
    assert_equal({1.0=>"foo", 2.0 => "bar", 3.0 => "baz"}, lua_eval('result = { "foo", "bar", "baz" }'))
  end

  def test_get_nested_table
    result = lua_eval(<<-'EOS')
      result = {
        foo = "FOO",
        bar = {
          bar1 = 1,
          bar2 = 2,
          bar3 = 3,
          barx = {
            barx1 = true,
            barx2 = false,
            barx3 = { "apple", "banana", "cherry" }
          }
        }
      }
    EOS
    ruby = {
      'foo' => "FOO",
      'bar' => {
        'bar1' => 1.0,
        'bar2' => 2.0,
        'bar3' => 3.0,
        'barx' => {
          'barx1' => true,
          'barx2' => false,
          'barx3' => { 1.0 => "apple", 2.0 => "banana", 3.0 => "cherry" }
        }
      }
    }
    assert_equal(ruby, result)
  end

  def test_set_nil
    assert_equal(nil, lua_eval('result = rubyvalue', "rubyvalue", nil))
  end
  
  def test_set_boolean
    assert_equal(true, lua_eval('result = rubyvalue', "rubyvalue", true))
    assert_equal(false, lua_eval('result = rubyvalue', "rubyvalue", false))
  end
  
  def test_set_number
    assert_equal(123.456, lua_eval('result = rubyvalue', "rubyvalue", 123.456))
  end

  def test_set_string
    assert_equal("string", lua_eval('result = rubyvalue', "rubyvalue", "string"))
  end
  
  def test_set_table
    assert_equal({"string"=>"string", "number" => 123}, lua_eval('result = rubyvalue', "rubyvalue", {"string"=>"string", "number" => 123}))
    assert_equal({'n'=>3, 1.0=>"foo", 2.0=>"bar", 3.0=>"baz"}, lua_eval('result = rubyvalue', "rubyvalue", ["foo","bar","baz"]))
  end
  
  def test_set_nested_table
    set_ruby = {
      'foo' => "FOO",
      'bar' => {
        'bar1' => 1,
        'bar2' => 2,
        'bar3' => 3,
        'barx' => {
          'barx1' => true,
          'barx2' => false,
          'barx3' => %w( apple banana cherry)
        }
      }
    }
    get_ruby = {
      'foo' => "FOO",
      'bar' => {
        'bar1' => 1.0,
        'bar2' => 2.0,
        'bar3' => 3.0,
        'barx' => {
          'barx1' => true,
          'barx2' => false,
          'barx3' => { 'n'=> 3.0, 1.0 => "apple", 2.0 => "banana", 3.0 => "cherry" }
        }
      }
    }
    result = lua_eval('result = rubyvalue', "rubyvalue", set_ruby)
    assert_equal(get_ruby, result)
  end

end
