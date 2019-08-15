# stuff = streams("allen"); ss = stuff[1];
# start = 1546300801000000000
# stop = 1546300830000000000
# items = BTrDB.values(ss, start, stop)
# rr  = nearest(ss, 0)


using BTrDB, UUIDs

# ss = BTrDB.Stream("832a5eb0-b8de-4eed-8786-9977e7d4c759", "streamv1", "allen/this/that", Dict("distiller"=>"","name"=>"streamv1","unit"=>"Volts","ingress"=>""), Dict{String,Any}("device"=>Dict{String,Any}("colors"=>Any["blue", "red"],"manufacture"=>Dict{String,Any}("make"=>"GE","year"=>2000)),"source"=>Any["data1.csv.gz", "data2.csv.gz"],"phase"=>"A","user"=>"Allen"), 0, 0)

tags = Dict{String, String}(  "distiller" => "",
         "name"      => "liger",
         "unit"      => "animal",
         "ingress"   => "")

annotations = Dict{String, Any}(
    "phase" => "A"
)
uuid = string(uuid4())
collection = "allen/zoo"

s = BTrDB.create(uuid, collection, tags, annotations)

# s = Stream("7c061c75-b308-429f-9229-8e58048a06c8", "liger", "allen/zoo", Dict("distiller"=>"","name"=>"liger","unit"=>"animal","ingress"=>""), Dict{String,Any}("phase"=>"A"), 10, 1)

# data = [Pair(1546300801000000000, 1.0), Pair(1546300802000000000, 2.0), Pair(1546300803000000000, 3.0)]
# insert(s, data)
# delete(s, 1546300802000000000, 1546300804000000000)


using BTrDB, UUIDs
s = refresh("974ee4e5-663c-438a-bb63-1ff75eb7e2fa")

annos = Dict{String, Any}(  "phase" => "Z",
         "number"      => 42)

setannotations(s, annos)

