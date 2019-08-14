export BTrDBException

struct BTrDBException <: Exception
    msg::String
    BTrDBException() = new("")
    BTrDBException(msg) = new(msg)
end
