--~ auther: Angryfox Su
--~ date: 2013-06-24
--~ MV列表的接口处理
local cjson =  require "cjson"
local redis =  require "redis_class"["Redis_Class"]
local commen =  require "commen_class"["Commen_Class"]
local MV_IMG_PATH = "http://imge.kugou.com/mvbigpic/"

local r = redis:new()
local c = commen:new()

local result = {status=0, data='',info=''}

local args = ngx.req.get_uri_args()
local tagid    = tonumber(args['tagid'])
local page     = tonumber(args['page']) or 1
local pagesize = tonumber(args['pagesize']) or 20
local i        = tonumber(args['i']) or 0

if ((pagesize == nil) or (page == nil) or (tagid == nil)) or (pagesize > 1000) then
	result['info'] = "Bad params!"
	print(cjson.encode(result))
	ngx.exit(ngx.HTTP_OK)
end

local skey = ngx.md5(tagid ..":"..page ..":"..pagesize ..":"..i.."video:list")
local rest, err = r:get(skey)

if rest == ngx.null then
	local start = 0
	if page > 0 then 
		start = (page - 1) * pagesize
	end
	
	if i == 1 then
		local utime = c:utime()
		url1 = "/video-list?tagid="..tagid.."&page="..start.."&pagesize="..pagesize .."&utime="..utime
		url2 = "/video-count?tagid="..tagid.."&utime="..utime
	else
		url1 = "/video-www-list?tagid="..tagid.."&page="..start.."&pagesize="..pagesize
		url2 = "/video-www-count?tagid="..tagid
	end
	
	local res1, res2 = ngx.location.capture_multi{
		{ url1 },
		{ url2 },
	}

	if (not res1.body) or (res1.body == ngx.null) or (res1.status ~= ngx.HTTP_OK) or (res2.status ~= ngx.HTTP_OK) then
		result['data'] = "no rurl data"
	elseif (res1.status == ngx.HTTP_OK) and (res2.status == ngx.HTTP_OK) then
		result['status'] = 1
		local raw_data  = cjson.decode(res1.body)
		local total_data = cjson.decode(res2.body)
		for i,v in ipairs(raw_data) do
			raw_data[i].bigpic  = string.gsub(raw_data[i].bigpic,'"\r\n',"")
			local pre = string.sub(raw_data[i].bigpic,1,8)
			
			raw_data[i].bigpic = MV_IMG_PATH ..pre .."/"..raw_data[i].bigpic
		end
		result['total'] = total_data[1].total
		result['data']  = raw_data
	end
	rest = cjson.encode(result)
	if result['status'] == 1 then 
		local ok, err =  r:setex(skey, rest)
	end
end

ngx.header["Content-Type"] = "application/json;charset=utf-8"
print(rest)