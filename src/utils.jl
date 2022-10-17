# Generate documentation for keywords
function _keydocs(descs, keys)
    doclines = (_keydocs(descs, k) for k in keys)
    # Return a block of text with all keywords documented
    return join(doclines, "\n")
end
function _keydocs(descs, key::Symbol)
    desc1 = replace(descs[key], "\n" => " ")
    return "- `$key`: $desc1"
end

# Generate documentation for arguments from a 
function _argdocs(descs)
    doclines = (_argdocs(descs, k) for k in keys(descs))
    return join(doclines, "\n")
end
_argdocs(descs, key::Symbol) = "\n    - `:$key`: $(descs[key])"

# Format a keywords for HTTP request and the GBIF api
_format_query(kw, allowed_keywords) =
    _format_query(values(kw), allowed_keywords)
function _format_query(nt::NamedTuple{K}, allowed_keywords) where K
    map(keys(nt)) do k
        k in allowed_keywords || throw(ArgumentError("Keyword $k not in $allowed_keywords"))
    end
    newkw = _clean_val(nt)
    return Dict{Symbol,Any}(pairs(newkw))
end

# Apply `f` to request if it was successful
function _handle_request(f, request)
   if request.status == 200
       return f(request.body)
   else
       error("Error making request: $(request.status)")
   end
end

function _clean_val(nt::NamedTuple{Keys}) where Keys
    map(NamedTuple{Keys}(Keys), nt) do k, v
        _clean_val(k, v)
    end
end
function _clean_val(k::Symbol, v)
    if k in keys(ENUMS)
        allowed_enums = keys(enum(k))
        v in allowed_enums || throw(ArgumentError("keyword $k must have values in $allowed_enums, got $v"))
        return v
    elseif v isa Tuple
        return join(v, ",")
    else
        return v
    end
end

_joinurl(a1, a2, args...) = string(a1, map(x -> string("/", x), (a2, args...))...)
