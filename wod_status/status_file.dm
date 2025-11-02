// wod_status/status_file.dm
// ѕишем статус в data/status.json каждые 10 секунд.
// project > из data/project.txt (любой текст, можно с [RUS])
// map     > из data/map.txt, иначе хвост world.name после последнего ':'.

#define STATUS_JSON_PATH  "data/status.json"
#define PROJECT_FILE_PATH "data/project.txt"
#define MAP_FILE_PATH     "data/map.txt"
// период в дес€тых дол€х секунды: 100 = 10 секунд
#define STATUS_PERIOD_DS 100

/proc/wod_trim(t)
	if (!t) return ""
	var/start = 1
	var/end = length(t) + 1
	// trim left (space/tab/dot)
	while (start < end)
		var/ch = copytext(t, start, start+1)
		var/code = text2ascii(ch)
		if (code == 32 || code == 9 || ch == ".")
			start++
		else
			break
	// trim right
	while (end > start)
		var/ch2 = copytext(t, end-1, end)
		var/code2 = text2ascii(ch2)
		if (code2 == 32 || code2 == 9 || ch2 == ".")
			end--
		else
			break
	return copytext(t, start, end)

/proc/wod_read_single_line(path)
	if (!fexists(path)) return ""
	var/s = file2text(path)
	if (!s) s = ""
	// удалить CR/LF
	var/clean = ""
	for (var/i = 1; i <= length(s); i++)
		var/ch = copytext(s, i, i+1)
		var/code = text2ascii(ch)
		if (code != 10 && code != 13)  // LF=10, CR=13
			clean += ch
	return wod_trim(clean)

/proc/wod_get_map_name()
	var/m = wod_read_single_line(MAP_FILE_PATH)
	if (m && m != "") return m

	var/name = (world.name ? world.name : "")
	if (!name || name == "") return ""

	// вз€ть всЄ после последнего ':'
	var/last = 0
	var/pos = findtext(name, ":")
	while (pos)
		last = pos
		pos = findtext(name, ":", last + 1)
	if (last)
		var/tail = copytext(name, last + 1)
		return wod_trim(tail)
	return wod_trim(name)

/proc/wod_write_status(project_name)
	// считаем игроков и имена
	var/players = 0
	var/list/names = list()
	for (var/client/C)
		players++
		if (C && C.mob)
			names += "[C.mob.name] ([C.ckey])"
		else if (C)
			names += "[C.ckey]"

	var/map_name = wod_get_map_name()

	// полезна€ нагрузка
	var/list/payload = list(
		"ok" = 1,
		"project" = project_name,
		"players" = players,
		"players_list" = names,
		"round_time" = round(world.time / 10),  // world.time Ч тики по 0.1 с
		"map" = map_name
	)

	// перезапись файла
	var/json = json_encode(payload)
	fdel(STATUS_JSON_PATH)
	text2file(json, STATUS_JSON_PATH)

world/New()
	..()
	spawn(0)
		while (TRUE)
			var/project_name = wod_read_single_line(PROJECT_FILE_PATH)
			wod_write_status(project_name)
			sleep(STATUS_PERIOD_DS)

world/Del()
	// финальна€ запись: оффлайн
	var/project_name = wod_read_single_line(PROJECT_FILE_PATH)
	var/map_name = wod_get_map_name()
	var/list/payload = list(
		"ok" = 0,
		"project" = project_name,
		"players" = 0,
		"players_list" = list(),
		"round_time" = 0,
		"map" = map_name
	)
	var/json = json_encode(payload)
	fdel(STATUS_JSON_PATH)
	text2file(json, STATUS_JSON_PATH)
	..()
