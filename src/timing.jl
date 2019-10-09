macro mytime(n, ex)
    quote
        println("@mytime: ", $n)
        local result = @time $(esc(ex))
        println()
        result
    end
end
