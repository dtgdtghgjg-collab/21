import json, pathlib, urllib.request, urllib.parse, time, re
ROOT = pathlib.Path('A:/opencode/21-IOS')
EXTRAS = json.loads((ROOT / 'habitica_extras.json').read_text(encoding='utf-8'))
ITEMS = json.loads((ROOT / 'habitica_items.json').read_text(encoding='utf-8-sig'))
CACHE_PATH = ROOT / 'habitica_translations_cache.json'
cache = json.loads(CACHE_PATH.read_text(encoding='utf-8-sig')) if CACHE_PATH.exists() else {}

def tr(text):
    text = (text or '').strip()
    if not text:
        return ''
    if text in cache:
        return cache[text]
    for attempt in range(6):
        try:
            q = urllib.parse.quote(text)
            url = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=ru&dt=t&q=' + q
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=15) as r:
                data = json.loads(r.read().decode('utf-8'))
                res = ''.join(seg[0] for seg in data[0] if seg and seg[0]).strip()
                if res:
                    cache[text] = res
                    time.sleep(0.8)
                    return res
        except Exception as e:
            print('translate retry', text[:40], e)
            time.sleep(5.0 * (2 ** attempt))
    return ''

def spaced(s):
    return re.sub(r'(?<=[a-z])(?=[A-Z])', ' ', s or '').strip()

def swift(s):
    return (s or '').replace(chr(34), chr(39)).replace(chr(10), ' ').replace(chr(13), ' ').strip()

items_by_id = {x['id']: x for x in ITEMS}
# Seasonal: reuse RU names from habiticaCatalog
seasonal_lines = []
seasonal_lines.append('// HabiticaSeasonalCatalog.swift')
seasonal_lines.append('// Auto-generated from content.json event dates + habitica_items.json RU names.')
seasonal_lines.append('// 282 seasonal gear items in 17 season groups. Sprites already in Assets.xcassets as item_hab-gear-*.')
seasonal_lines.append('')
seasonal_lines.append('struct HabiticaSeasonalEntry { let catalogId: String; let season: String; let seasonLabel: String; let start: String; let end: String }')
seasonal_lines.append('')
seasonal_lines.append('let habiticaSeasonalEntries: [HabiticaSeasonalEntry] = [')
for e in EXTRAS['seasonal']:
    seasonal_lines.append('    HabiticaSeasonalEntry(catalogId: "' + swift(e['catalog_id']) + '", season: "' + swift(e['season']) + '", seasonLabel: "' + swift(e['season_label']) + '", start: "' + swift(e['start']) + '", end: "' + swift(e['end']) + '"),')
seasonal_lines.append(']')
seasonal_lines.append('')
seasonal_lines.append('var habiticaSeasonalItems: [CatalogItem] { habiticaSeasonalEntries.compactMap { e in habiticaCatalog.first { $0.id == e.catalogId } } }')
seasonal_lines.append('var habiticaSeasonLabels: [String] { Array(Set(habiticaSeasonalEntries.map { $0.seasonLabel })).sorted() }')
(ROOT / 'TwentyOne' / 'Models' / 'HabiticaSeasonalCatalog.swift').write_text(chr(10).join(seasonal_lines), encoding='utf-8')
print('seasonal swift', len(EXTRAS['seasonal']))
# Pets: translate distinct eggs and potions only, compose as Egg (Potion)
eggs = sorted({p.get('egg') or '' for p in EXTRAS['pets'] if p.get('egg')})
potions = sorted({p.get('potion') or '' for p in EXTRAS['pets'] if p.get('potion')})
egg_ru = {}
for e in eggs:
    egg_ru[e] = tr(spaced(e)) or spaced(e)
potion_ru = {}
for p in potions:
    potion_ru[p] = tr(spaced(p)) or spaced(p)
CACHE_PATH.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding='utf-8')
print('eggs', len(eggs), 'potions', len(potions))
pet_lines = []
pet_lines.append('// HabiticaPetsCatalog.swift')
pet_lines.append('// Auto-generated from content.json petInfo. 676 pets: drop 90, premium 117, quest 450, special 19.')
pet_lines.append('// Sprites in Assets.xcassets as pet_<key>.imageset, source stable_Pet-<key>.png from habitica-assets S3.')
pet_lines.append('// RU name is Egg (Potion), e.g. Volк (Belyi) -> translated egg and potion parts.')
pet_lines.append('')
pet_lines.append('struct HabiticaPet: Identifiable { let id: String; let key: String; let name: String; let nameEn: String; let type: String; let egg: String; let potion: String; var assetName: String { "pet_" + id } }')
pet_lines.append('')
pet_lines.append('let habiticaPets: [HabiticaPet] = [')
for p in EXTRAS['pets']:
    key = p['key']
    pid = key.lower().replace('_', '-').replace(' ', '-')
    pid = ''.join(c for c in pid if c.isalnum() or c == '-')
    if p.get('egg') and p.get('potion'):
        name_ru = egg_ru.get(p['egg'], p['egg']) + ' (' + potion_ru.get(p['potion'], p['potion']) + ')'
    else:
        name_ru = tr(p.get('text_en') or key) or p.get('text_en') or key
    pet_lines.append('    HabiticaPet(id: "' + swift(pid) + '", key: "' + swift(key) + '", name: "' + swift(name_ru) + '", nameEn: "' + swift(p.get('text_en') or key) + '", type: "' + swift(p.get('type') or '') + '", egg: "' + swift(p.get('egg') or '') + '", potion: "' + swift(p.get('potion') or '') + '"),')
pet_lines.append(']')
(ROOT / 'TwentyOne' / 'Models' / 'HabiticaPetsCatalog.swift').write_text(chr(10).join(pet_lines), encoding='utf-8')
CACHE_PATH.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding='utf-8')
print('pets swift', len(EXTRAS['pets']))
# Achievements: RU titles/descs, icon asset is achievement-<icon> already downloaded (incl. 2x variants)
ACH_RU = {'dilatoryQuest': ('Дракон Дилатори', 'Победить Дракона Дилатори в квесте.'), 'stressbeastQuest': ('Стрессбист', 'Победить Мерзкого Стрессбиста в квесте.'), 'burnoutQuest': ('Выгорание', 'Победить Выгорание в квесте.'), 'bewilderQuest': ('Очарователь', 'Победить Очарователя в квесте.'), 'dysheartenerQuest': ('Разбивающий сердца', 'Победить Разбивающего сердца в квесте.'), 'snowball': ('Снежок', 'Закидать друзей снежками.'), 'spookySparkles': ('Жуткие искры', 'Закидать друзей жуткими искрами.'), 'shinySeed': ('Блестящее семя', 'Закидать друзей блестящими семенами.'), 'seafoam': ('Морская пена', 'Закидать друзей морской пеной.'), 'beastMaster': ('Повелитель зверей', 'Собрать всех питомцев.'), 'mountMaster': ('Повелитель скакунов', 'Приручить всех скакунов.'), 'triadBingo': ('Триада бинго', 'Найти всех питомцев, приручить всех скакунов и найти всех питомцев снова.'), 'partyUp': ('Собрать команду', 'Создать или вступить в команду.'), 'partyOn': ('Команда в деле', 'Пройти квест вместе с командой.'), 'streak': ('Серия', 'Выполнять дейлик 21 день подряд.'), 'perfect': ('Идеальный день', 'Выполнить все дейлики за день.'), 'royallyLoyal': ('Королевская верность', 'Быть подписчиком 12 месяцев подряд.'), 'joinedGuild': ('В гильдии', 'Вступить в гильдию.'), 'joinedChallenge': ('В испытании', 'Вступить в испытание.'), 'invitedFriend': ('Пригласил друга', 'Пригласить друга в Habitica.'), 'lostMasterclasser': ('Потерянный мастер', 'Особое достижение мастер-класса.'), 'contributor': ('Участник', 'Внести вклад в Habitica.'), 'npc': ('NPC', 'Помочь NPC Habitica.'), 'kickstarter': ('Кикстартер', 'Поддержать Habitica на Kickstarter.'), 'veteran': ('Ветеран', 'Быть с Habitica с ранних дней.'), 'originalUser': ('Первопроходец', 'Один из первых пользователей Habitica.'), 'habitSurveys': ('Опросы', 'Пройти опрос Habitica.'), 'habiticaDays': ('Дни в Habitica', 'Отметить годовщину в Habitica.'), 'habitBirthdays': ('День рождения Habitica', 'Отметить день рождения Habitica.'), 'costumeContests': ('Конкурс костюмов', 'Участвовать в конкурсе костюмов.'), 'healerUltimateGear': ('Ультимативное снаряжение лекаря', 'Собрать ультимативное снаряжение лекаря.'), 'rogueUltimateGear': ('Ультимативное снаряжение разбойника', 'Собрать ультимативное снаряжение разбойника.'), 'warriorUltimateGear': ('Ультимативное снаряжение воина', 'Собрать ультимативное снаряжение воина.'), 'mageUltimateGear': ('Ультимативное снаряжение мага', 'Собрать ультимативное снаряжение мага.'), 'greetingCards': ('Открытки приветствия', 'Отправить открытку приветствия.'), 'thankyouCards': ('Открытки благодарности', 'Отправить открытку благодарности.'), 'nyeCards': ('Новогодние открытки', 'Отправить новогоднюю открытку.'), 'valentineCards': ('Открытки ко Дню святого Валентина', 'Отправить валентинку.'), 'birthdayCards': ('Открытки ко дню рождения', 'Отправить открытку ко дню рождения.'), 'congratsCards': ('Открытки поздравления', 'Отправить открытку с поздравлением.'), 'getwellCards': ('Открытки выздоровления', 'Отправить открытку с пожеланием выздоровления.'), 'goodluckCards': ('Открытки удачи', 'Отправить открытку с пожеланием удачи.')}
ach_lines = []
ach_lines.append('// HabiticaAchievementsCatalog.swift')
ach_lines.append('// Auto-generated from content.json achievements. 42 achievements, icons in Assets.xcassets as achievement-<icon>.imageset.')
ach_lines.append('')
ach_lines.append('struct HabiticaAchievement: Identifiable { let id: String; let title: String; let desc: String; let icon: String; var assetName: String { icon } }')
ach_lines.append('')
ach_lines.append('let habiticaAchievements: [HabiticaAchievement] = [')
for a in EXTRAS['achievements']:
    title, desc = ACH_RU.get(a['key'], (a['key'], ''))
    ach_lines.append('    HabiticaAchievement(id: "hab-ach-' + swift(a['key']) + '", title: "' + swift(title) + '", desc: "' + swift(desc) + '", icon: "' + swift(a['asset_name']) + '"),')
ach_lines.append(']')
(ROOT / 'TwentyOne' / 'Models' / 'HabiticaAchievementsCatalog.swift').write_text(chr(10).join(ach_lines), encoding='utf-8')
print('achievements swift', len(EXTRAS['achievements']))
print('done')
