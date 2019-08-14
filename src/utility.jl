
using HTTP, JSON, Base64


function encodeUUID(txt::String)
    parsed = join(split(txt, "-"))
    parts = [parsed[i:i+1] for i in 1:2:32]
    return base64encode(IOBuffer(hex2bytes(parsed)))
end

function decodeUUID(txt::String)
    function zeropad(val::String)
        if length(val) == 2
            return val
        elseif length(val) == 1
            return "0" * val
        elseif length(val) == 0
            return "00"
        else
            # throw(Exception("invalid String"))
        end
    end
    parts = string.(base64decode(txt), base=16)
    parts = [zeropad(val) for val in parts]
    parts = join([zeropad(val) for val in parts])

    return "$(parts[1:8])-$(parts[9:12])-$(parts[13:16])-$(parts[17:20])-$(parts[21:end])"
end


function stitch(parts::Array{String,1}, label::String)
    pattern = Regex("{\"result\": ")
    results = nothing
    for item in parts
        data = JSON.parse(item)["result"]
        if results === nothing
            results = data[label]
        else
            results = vcat(results, data[label])
        end
    end
    return results
end


function parse_api_results(content, label)
    pattern = Regex("{\"result\": ")
    numtokens = length(collect(eachmatch(Regex("{\"result"), content)))

    if numtokens == 1
        data = JSON.parse(content)
        return data["result"][label]
    elseif numtokens > 1
        parts = string.(split(content, "\n"))
        parts = [item for item in parts if item != ""]
        return stitch(parts, label)
    else

    end
end

function apicall(url::String, body::String)
    headers = [
        "Content-Type" => "application/json",
        "Authorization" => "Bearer $APIKEY"
    ]

    io = Base.BufferStream()
    response = HTTP.request("POST", url, headers, body, response_stream=io; verbose=0)
    close(io)

    # TODO: handle stat error here?
    # if body["stat"] != nothing && haskey(body["stat"], "code")
    #     throw(BTrDBException(body["stat"]["message"]))
    #  end

    return String(read(io))
end



