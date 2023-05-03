-- ._.

local english = "en"
local spanish = "es"
local german = "de"
local french = "fr"
local function ChatTranslate(ply, text, teamchat, isdead)
	Translate("fr", "en", text)
end
hook.Add("OnPlayerChat", "Translate", ChatTranslate)

local function TranslateToChat(ply, cmd, args)
	local text = string.Implode(" ", args)
	TranslateTo("en", "fr", text)
end
concommand.Add("translate", TranslateToChat)

function TranslateTo(from, to, text)
	local text = text:gsub("%s", "%%20")
	http.Get("http://translate.google.com/translate_a/t?client=t&text="..text.."&hl="..to.."&sl="..from.."&tl="..to.."&pc=0", "", TranslateToCallback)
end

function TranslateToCallback(contents, size)
	local tab = string.Explode(",", contents)
	local translated = string.Right(tab[1], string.len(tab[1])-4)
	local translated = string.Left(translated, string.len(translated)-1)
	RunConsoleCommand("say", translated)
end

function Translate(from, to, text)
	local text = text:gsub("%s", "%%20")
	http.Get("http://translate.google.com/translate_a/t?client=t&text="..text.."&hl="..to.."&sl="..from.."&tl="..to.."&pc=0", "", TranslateCallback)
end

function TranslateCallback(contents, size)
	local tab = string.Explode(",", contents)
	local translated = string.Right(tab[1], string.len(tab[1])-3)
	chat.AddText(translated)
end