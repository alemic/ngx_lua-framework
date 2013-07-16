--~ auther: Angryfox Su
--~ date: 2013-07-02
--~ 精选集列表的接口处理
--~ link:http://i.kugou.com/special/list?page=1&pagesize=10&sort=0&type=0
--~ link:http://i.kugou.com/special/list?page=1&pagesize=10&sort=0&type=1
local cjson  =  require "cjson"
local redis  =  require "redis_class"["Redis_Class"]
local commen =  require "commen_class"["Commen_Class"]

local r = redis:new()
local c = commen:new()

local result = {status=0, data='',info='',total= 0}
--~ print(ngx.var.arg_tagid)

local args      = ngx.req.get_uri_args()
--~ type 0,1,2,3 0为全部
local typeid    = tonumber(args['type']) or 0
local page      = tonumber(args['page']) or 1
local pagesize  = tonumber(args['pagesize']) or 20
local sortid    = tonumber(args['sort']) or 1

if  ((typeid == nil) or (sortid == nil) or (typeid > 3)) then
	result['info'] = "Bad params!"
	print(cjson.encode(result))
	ngx.exit(200)
end

local skey = ngx.md5(typeid ..":"..sortid..":"..page..":"..pagesize..":special:list")
local rest, err = r:get(skey)
--~ ngx.exit(ngx.HTTP_OK)
rest = ngx.null
if rest == ngx.null then
	local start = 0
	if page > 0 then 
		start = (page - 1) * pagesize
	end
	local orderby = 'addtime'
	local url1 = ""
	local url2 = ""
	if sortid == 1 then
		orderby = 'access_count'
	end
	if typeid ~= 0 then 
		local begin,finish = c:difforder(typeid)
		url1 = "/special-list-time?start="..start.."&pagesize="..pagesize .."&begin="..begin .."&finish="..finish.."&orderby=" .. orderby
		print(url1)
		url2 = "/special-list-time-total?begin="..begin .."&finish="..finish
	else
		url1 = "/special-list?start="..start.."&pagesize="..pagesize .."&orderby=" .. orderby
		url2 = "/special-list-total"
	end 
	
	local res1,res2 = ngx.location.capture_multi{
		{url1},{url2},
	}
	if (not res1.body) or (res1.body == ngx.null) or (res1.status ~= ngx.HTTP_OK) or (res2.status ~= ngx.HTTP_OK) then
		result['data'] = "no rurl data"
	elseif (res1.status == ngx.HTTP_OK) and (res2.status == ngx.HTTP_OK) then
		result['status'] = 1
		local raw_data = cjson.decode(res1.body)
		local count    = cjson.decode(res2.body)
		for i,v in ipairs(raw_data) do			
--~ 		图片切割，含有2张图片
			if string.len(raw_data[i].img) > 76 then
				local images = string.split(raw_data[i].img, '|')
				raw_data[i].img = images[1]
			end
--~ 		评分类分拆
			local list = string.split(raw_data[i].grade, '.')
			raw_data[i]['grade_int'] = list[1]
			raw_data[i]['grade_float'] = list[2]
--~ 		分拆描述类
			local desc = string.split(raw_data[i].intro, '|')
			raw_data[i]['author'] = string.gsub(desc[2],"出品人：","")
			raw_data[i]['intro']  = desc[3]
		end
		result['data'] = raw_data
		result['total'] = count[1].total
		
	end
	rest = cjson.encode(result)
	if result['status'] == 1 then 
		local ok, err =  r:setex(skey, rest)
	end
end

ngx.header["Content-Type"] = "application/json;charset=utf-8"
print(rest)