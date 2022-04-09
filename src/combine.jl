const DATE_RE = r"\d{4}_\d{2}_\d{2}"

function combinedf(fp1::String, s1, fp2::String, s2)
    df1 = DataFrame(CSV.File(fp1))
    df2 = DataFrame(CSV.File(fp2))

    bv1 = falses(size(df1,1))
    bv2 = falses(size(df2,1))

    for s in s1
        bv1 .+= df1.sol .== s
    end
    idx1 = BitVector(min.(bv1, 1))
    for s in s2
        bv2 .+= df2.sol .== s
    end
    idx2 = BitVector(min.(bv2, 1))

    return vcat(df1[idx1,:], df2[idx2,:])
end

function latest(path::AbstractString, prefix::AbstractString="")
    files = readdir(path)
    full_re = prefix * r".*" * DATE_RE

    dt_latest = DateTime(0)
    filename_latest = ""

    for filename in files
        re_match = match(full_re, filename)
        if !isnothing(re_match)
            dt_str = match(DATE_RE, filename).match
            dt = DateTime(dt_str, dateformat"yyyy_mm_dd")
            if dt > dt_latest
                dt_latest = dt
                filename_latest = filename
            end
        end
    end
    if dt_latest == DateTime(0)
        throw(DomainError, "No Matches")
    else
        return joinpath(path, filename_latest)
    end
end
