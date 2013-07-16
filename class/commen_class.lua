module(..., package.seeall)

Commen_Class = class('Commen_Class')

function Commen_Class:initialize()
end

function Commen_Class:difforder(typeid)
	if typeid == 1 then
		start  = os.date("%Y-%m-%d",os.time()-(8*86400))
		finish = os.date("%Y-%m-%d",os.time()-(2*86400))
	elseif typeid == 2 then
		start = os.date("%Y-%m-%d",os.time({year=os.date("%Y",os.time()),month=os.date("%m",os.time())-1,day=os.date("%d",os.time())-8,hour=0,min=0})) 
		finish = os.date("%Y-%m-%d",os.time()-(8*86400))
	elseif typeid == 3 then
		start = os.date("%Y-%m-%d",os.time({year=os.date("%Y",os.time()),month=os.date("%m",os.time())-3,day=os.date("%d",os.time())-8,hour=0,min=0})) 
		finish = os.date("%Y-%m-%d",os.time({year=os.date("%Y",os.time()),month=os.date("%m",os.time())-1,day=os.date("%d",os.time())-8,hour=0,min=0})) 
	else
		start  = ngx.null
		finish = ngx.null
	end
	return start, finish
end

function Commen_Class:utime()
	utime = os.time() - (3 * 4 * 7 * 24 * 60 * 60)
	return utime
end

--~ 专辑列表页
function Commen_Class:albumlist(typeid, orderid, page, pagesize)
	local start = 0
	if page > 0 then 
		start = (page - 1) * pagesize
	end
	if typeid > 0 and typeid < 5 then 
		typeby = "AND language_type=".. typeid
	else
		typeby = ""
	end
	
	if orderid == 1 then
		orderby = "ORDER BY publish_time DESC,albumid DESC"
	elseif orderid == 2 then
		orderby = "ORDER BY grade DESC,grade_count DESC,albumid DESC"
	else
		orderby = ""
	end
	
	local sql = "SELECT albumid,albumname,singername,img,publish_time,company,grade FROM k_album WHERE is_publish=1 "..typeby.." AND source != 12 "..orderby .." LIMIT "..start ..",".. pagesize
	return sql
end

--~ 分类的专辑信息
function Commen_Class:catalbum(typeid, tagid, page, pagesize)
	local start = 0
	if page > 0 then 
		start = (page - 1) * pagesize
	end
	
	local corderby = ""
--~ 热度排序。--~browse
	if typeid == 0  then
		corderby = "ORDER BY publish_time DESC,albumid DESC"
	elseif typeid == 1 then
--~ 热度排序。--~browse
		corderby = "ORDER BY access_count DESC,grade DESC,grade_count DESC,albumid DESC"
	elseif typeid == 2 then
--~ 评分排序。 grade
		corderby = "ORDER BY access_count DESC,grade DESC,grade_count DESC,albumid DESC"
	end
	
	local sql = "SELECT the_first,b.albumid,b.albumname,b.img,b.singername,b.grade FROM (SELECT albumid FROM k_album_tag WHERE tagid="..tagid..") AS a LEFT JOIN k_album AS b ON a.albumid=b.albumid WHERE b.is_publish=1 "..corderby.." LIMIT "..start..","..pagesize
	return sql
end

--~ 分类的歌曲
function Commen_Class:catsong(tagid, page, pagesize)
	local start = 0
	if page > 0 then 
		start = (page - 1) * pagesize
	end
	
	local corderby = ""
	if tagid == 71  then
		corderby = "GROUP BY filename"
	end
	
	local sql = "SELECT b.mixsongid AS id,CONCAT(IFNULL(singername,choric_singer),' - ',songname) AS filename,b.hash,filesize,extname,timelength AS duration,bitrate,ownercount,addtime,is_file_head,hash_320,hash_ape FROM (SELECT mixsongid FROM k_song_tag WHERE tagid="..tagid..") AS a LEFT JOIN k_mixsong AS b ON a.mixsongid=b.mixsongid WHERE LENGTH(b.hash)=32 AND b.is_publish=1 AND b.editor != '' "..corderby .." ORDER BY b.sort ASC LIMIT "..start..",".. pagesize
	return sql
end

--~ 分类精选集信息
function Commen_Class:catspecial(tagid, typeid, page, pagesize)
	local start = 0
	if page > 0 then 
		start = (page - 1) * pagesize
	end
	local corderby = ""
	--~ 时间排序--~browse
	if typeid == 0  then
		corderby = "ORDER BY KS.addtime DESC"
	elseif typeid == 1 then
--~ 热度排序--~browse
		corderby = "ORDER BY KS.access_count DESC,KS.grade DESC,KS.grade_count DESC,KS.specialid DESC"
	elseif typeid == 2 then
--~ 评分排序 grade
		corderby = "ORDER BY KS.grade DESC,KS.grade_count DESC,KS.access_count DESC,KS.specialid DESC"
	end

	local sql = "SELECT KS.specialid,KS.specialname,KS.intro,KS.img,KS.grade,KS.song_count FROM k_special AS KS RIGHT JOIN k_collect_tag AS KCT ON   KS.specialid = KCT.newid WHERE  KS.is_publish =1 AND  KCT.tagid="..tagid .." "..corderby .." LIMIT "..start..",".. pagesize
	return sql
end

--~ 获得排行榜最大的id
function Commen_Class:maxvol(classid, vtable)
	local sql = "SELECT MAX(volume) AS volume FROM ".. vtable .." WHERE is_publish =1 AND cid ="..classid;
	return sql
end

--~ 歌手的列表信息singerclass('A', 2, '0_0', 1 ,20)
function Commen_Class:singerclass(cindex, singerclass, showtype, page ,pagesize)
	local cindex = string.upper(cindex)
	local start = 0
	if page > 0 then 
		start = (page - 1) * pagesize
	end
	local where    = self:leftclass(singerclass)
	local orderby  = self:gettype(showtype)
--~ 拼接最终的计数和查询两条SQL语句
	if (cindex == 'null') then
		where = where .. " AND cindex < 'A'"
	elseif (cindex ~= 'all') then
		where = where .. " AND cindex='"..cindex .."' "
	end
	
	if (orderby=="AND source != 12 ORDER BY publish_time DESC") then
		sqlcount = "SELECT COUNT(*) as total FROM k_singer WHERE "..where.." AND source != 12"
		sql = "SELECT singerid,singername,img,sort_offset,(SELECT MAX(publish_time) FROM k_album WHERE k_singer.singerid=k_album.singerid ) AS publish_time FROM k_singer WHERE "..where.." "..orderby.." LIMIT "..start..",".. pagesize
	else
		sqlcount = "SELECT COUNT(*) as total FROM k_singer WHERE "..where 
		sql = "SELECT singerid,singername,img,sort_offset FROM k_singer WHERE "..where.." "..orderby.." LIMIT "..start..","..pagesize
	end
			
	return sql, sqlcount
end

function Commen_Class:leftclass(singerclass)
	local class = {
		[1] ="is_publish=1",											--~全部歌手
		[2] ="language='华语' and is_publish=1 and sextype=1",			--~华语男歌手
		[3] ="language='华语' and is_publish=1 and sextype=0",			--~华语女歌手
		[4] ="language='华语' and is_publish=1 and sextype in(2,3)",	--~华语组合
		[5] ="language='日韩' and is_publish=1 and sextype=1",			--~日韩男歌手
		[6] ="language='日韩' and is_publish=1 and sextype=0",			--~日韩女歌手
		[7] ="language='日韩' and is_publish=1 and sextype in(2,3)",	--~日韩组合
		[8] ="language='欧美' and is_publish=1 and sextype=1",			--~欧美男歌手
		[9] ="language='欧美' and is_publish=1 and sextype=0",			--~欧美女歌手
		[10] ="language='欧美' and is_publish=1 and sextype in(2,3)",	--~欧美组合
		[11] ="language='其他' and is_publish=1",						--~其他
	}
	return class[singerclass] or class[1]
end

function Commen_Class:gettype(showtype)
	local types = {
		['0_0'] = "ORDER BY edit_sort ASC",
		['0_1'] = "ORDER BY sort asc,singerid ASC",
		['0_2'] = "AND source != 12 ORDER BY publish_time DESC",
		['1_0'] = "ORDER BY edit_sort ASC",
		['1_1'] = "ORDER BY sort ASC,singerid ASC",
		['1_2'] = "AND source != 12 ORDER BY publish_time DESC",
	}
	return types[showtype] or types['0_0']
end