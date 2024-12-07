local L = {}

local locale = GetLocale()

if (locale == "enUS" or locale == 'enGB') then
    L["VERSION"] = "Version"
    L["SAVE_SPELLS"] = "Save Spells"
    L["CANCEL"] = "Cancel"
    L["ENABLE_DEBUGGER"] = "Enable Debugger"
    L["ENABLE_AUDIO_CUE"] = "Enable Audio Cue"
    L["PROC"] = "Proc"
    L["GLOW"] = "Glow"
    L["PIXEL"] = "Pixel"
    L["CAST"] = "Cast"
    L["RED"] = "Red"
    L["GREEN"] = "Green"
    L["BLUE"] = "Blue"
    L["ALPHA"] = "Alpha"
    L["LINES"] = "Lines"
    L["SCALE"] = "Scale"
    L["FREQUENCY"] = "Frequency"
    L["THICKNESS"] = "Thickness"
    L["UNSAVED_CHANGES"] = "You have unsaved changes!"
    L["ABOUT_MOD"] = "About the mod:\n\n" ..
            "• If the current mob is a boss, class interrupt spells will be highlighted instead of user selections.\n\n" ..
            "• The debugger is mainly for developer use. Enabling it will cause a lot of chat noise.\n\n" ..
            "• Please let the developer of any bugs you come across at either the GitHub repository, CurseForge or" ..
            " WoWInterface.\n\n" ..
            "• Please let the developer know if any spells are missing from the list of spells available for selection."
elseif locale == "deDE" then
    L["VERSION"] = "Version"
    L["SAVE_SPELLS"] = "Zauber speichern"
    L["CANCEL"] = "Abbrechen"
    L["ENABLE_DEBUGGER"] = "Debugger aktivieren"
    L["ENABLE_AUDIO_CUE"] = "Audio-Hinweis aktivieren"
    L["PROC"] = "Proc"
    L["GLOW"] = "Leuchten"
    L["PIXEL"] = "Pixel"
    L["CAST"] = "Wirken"
    L["RED"] = "Rot"
    L["GREEN"] = "Grün"
    L["BLUE"] = "Blau"
    L["ALPHA"] = "Alpha"
    L["LINES"] = "Linien"
    L["SCALE"] = "Skalierung"
    L["FREQUENCY"] = "Frequenz"
    L["THICKNESS"] = "Dicke"
    L["UNSAVED_CHANGES"] = "Sie haben ungespeicherte Änderungen!"
    L["ABOUT_MOD"] = "Über das Mod:\n\n" ..
            "• Wenn der aktuelle Gegner ein Boss ist, werden Klassenunterbrechungszauber hervorgehoben anstelle der vom Benutzer ausgewählten.\n\n" ..
            "• Der Debugger ist hauptsächlich für Entwickler gedacht. Wenn er aktiviert ist, wird er viele Chatnachrichten erzeugen.\n\n" ..
            "• Bitte melden Sie dem Entwickler alle Fehler, die Sie entweder im GitHub-Repository, auf CurseForge oder" ..
            " WoWInterface finden.\n\n" ..
            "• Bitte informieren Sie den Entwickler, wenn Zauber in der Liste der zur Auswahl stehenden Zauber fehlen."
elseif locale == "esMX" then
    L["VERSION"] = "Versión"
    L["SAVE_SPELLS"] = "Guardar hechizos"
    L["CANCEL"] = "Cancelar"
    L["ENABLE_DEBUGGER"] = "Habilitar depurador"
    L["ENABLE_AUDIO_CUE"] = "Habilitar señal de audio"
    L["PROC"] = "Proc"
    L["GLOW"] = "Brillo"
    L["PIXEL"] = "Píxel"
    L["CAST"] = "Lanzar"
    L["RED"] = "Rojo"
    L["GREEN"] = "Verde"
    L["BLUE"] = "Azul"
    L["ALPHA"] = "Alfa"
    L["LINES"] = "Líneas"
    L["SCALE"] = "Escala"
    L["FREQUENCY"] = "Frecuencia"
    L["THICKNESS"] = "Grosor"
    L["UNSAVED_CHANGES"] = "¡Tienes cambios no guardados!"
    L["ABOUT_MOD"] = "Acerca del mod:\n\n" ..
            "• Si el enemigo actual es un jefe, los hechizos de interrupción de clase se resaltarán en lugar de las selecciones del usuario.\n\n" ..
            "• El depurador es principalmente para uso de desarrolladores. Activarlo generará mucho ruido en el chat.\n\n" ..
            "• Por favor, informe al desarrollador de cualquier error que encuentre en el repositorio de GitHub, CurseForge o" ..
            " WoWInterface.\n\n" ..
            "• Por favor, informe al desarrollador si faltan hechizos en la lista de hechizos disponibles para selección."
elseif locale == 'ptBR' then
    L["VERSION"] = "Versão"
    L["SAVE_SPELLS"] = "Salvar Feitiços"
    L["CANCEL"] = "Cancelar"
    L["ENABLE_DEBUGGER"] = "Ativar Depurador"
    L["ENABLE_AUDIO_CUE"] = "Ativar Sinal de Áudio"
    L["PROC"] = "Proc"
    L["GLOW"] = "Brilho"
    L["PIXEL"] = "Pixel"
    L["CAST"] = "Lançar"
    L["RED"] = "Vermelho"
    L["GREEN"] = "Verde"
    L["BLUE"] = "Azul"
    L["ALPHA"] = "Alfa"
    L["LINES"] = "Linhas"
    L["SCALE"] = "Escala"
    L["FREQUENCY"] = "Frequência"
    L["THICKNESS"] = "Espessura"
    L["UNSAVED_CHANGES"] = "Você tem alterações não salvas!"
    L["ABOUT_MOD"] = "Sobre o mod:\n\n" ..
            "• Se o inimigo atual for um chefe, feitiços de interrupção de classe serão destacados em vez das seleções do usuário.\n\n" ..
            "• O depurador é principalmente para uso dos desenvolvedores. Ativá-lo gerará muito ruído no chat.\n\n" ..
            "• Informe ao desenvolvedor sobre qualquer erro que você encontrar, seja no repositório do GitHub, no CurseForge ou" ..
            " no WoWInterface.\n\n" ..
            "• Por favor, informe ao desenvolvedor se algum feitiço estiver faltando na lista de feitiços disponíveis para seleção."
elseif (locale == 'zhCN' or locale == 'enCN') then
    L["VERSION"] = "版本"
    L["SAVE_SPELLS"] = "保存法术"
    L["CANCEL"] = "取消"
    L["ENABLE_DEBUGGER"] = "启用调试器"
    L["ENABLE_AUDIO_CUE"] = "启用音频提示"
    L["PROC"] = "触发"
    L["GLOW"] = "发光"
    L["PIXEL"] = "像素"
    L["CAST"] = "施法"
    L["RED"] = "红色"
    L["GREEN"] = "绿色"
    L["BLUE"] = "蓝色"
    L["ALPHA"] = "透明度"
    L["LINES"] = "线条"
    L["SCALE"] = "缩放"
    L["FREQUENCY"] = "频率"
    L["THICKNESS"] = "粗细"
    L["UNSAVED_CHANGES"] = "你有未保存的更改！"
    L["ABOUT_MOD"] = "关于此模组:\n\n" ..
            "• 如果当前敌人是首领，类技能打断法术将被高亮显示，而不是用户选择的法术。\n\n" ..
            "• 调试器主要用于开发者。启用后会在聊天中生成大量信息。\n\n" ..
            "• 请将您发现的任何错误报告给开发者，可以通过 GitHub 仓库、CurseForge 或 WoWInterface。\n\n" ..
            "• 如果有任何法术缺失，请通知开发者，将其加入可选法术列表。"
elseif locale == 'frFR' then
    L["VERSION"] = "Version"
    L["SAVE_SPELLS"] = "Sauvegarder les sorts"
    L["CANCEL"] = "Annuler"
    L["ENABLE_DEBUGGER"] = "Activer le débogueur"
    L["ENABLE_AUDIO_CUE"] = "Activer le signal audio"
    L["PROC"] = "Proc"
    L["GLOW"] = "Lueur"
    L["PIXEL"] = "Pixel"
    L["CAST"] = "Incantation"
    L["RED"] = "Rouge"
    L["GREEN"] = "Vert"
    L["BLUE"] = "Bleu"
    L["ALPHA"] = "Alpha"
    L["LINES"] = "Lignes"
    L["SCALE"] = "Échelle"
    L["FREQUENCY"] = "Fréquence"
    L["THICKNESS"] = "Épaisseur"
    L["UNSAVED_CHANGES"] = "Vous avez des modifications non sauvegardées !"
    L["ABOUT_MOD"] = "À propos du mod :\n\n" ..
            "• Si l'ennemi actuel est un boss, les sorts d'interruption de classe seront mis en évidence au lieu des sélections de l'utilisateur.\n\n" ..
            "• Le débogueur est principalement destiné à l'usage des développeurs. L'activer génèrera beaucoup de messages dans le chat.\n\n" ..
            "• Merci d'informer le développeur de tout bug rencontré via le dépôt GitHub, CurseForge ou" ..
            " WoWInterface.\n\n" ..
            "• Merci d'informer le développeur si des sorts sont manquants dans la liste des sorts disponibles."
elseif locale == 'itIT' then
    L["VERSION"] = "Versione"
    L["SAVE_SPELLS"] = "Salva incantesimi"
    L["CANCEL"] = "Annulla"
    L["ENABLE_DEBUGGER"] = "Abilita debugger"
    L["ENABLE_AUDIO_CUE"] = "Abilita segnale audio"
    L["PROC"] = "Proc"
    L["GLOW"] = "Bagliore"
    L["PIXEL"] = "Pixel"
    L["CAST"] = "Lancio"
    L["RED"] = "Rosso"
    L["GREEN"] = "Verde"
    L["BLUE"] = "Blu"
    L["ALPHA"] = "Alpha"
    L["LINES"] = "Linee"
    L["SCALE"] = "Scala"
    L["FREQUENCY"] = "Frequenza"
    L["THICKNESS"] = "Spessore"
    L["UNSAVED_CHANGES"] = "Hai modifiche non salvate!"
    L["ABOUT_MOD"] = "Informazioni sul mod:\n\n" ..
            "• Se il nemico attuale è un boss, gli incantesimi di interruzione della classe verranno evidenziati al posto delle selezioni dell'utente.\n\n" ..
            "• Il debugger è principalmente per uso degli sviluppatori. Abilitarlo genererà molti messaggi in chat.\n\n" ..
            "• Si prega di segnalare eventuali bug allo sviluppatore su GitHub, CurseForge o" ..
            " WoWInterface.\n\n" ..
            "• Si prega di informare lo sviluppatore se mancano incantesimi nell'elenco degli incantesimi disponibili."
elseif locale == 'ruRU' then
    L["VERSION"] = "Версия"
    L["SAVE_SPELLS"] = "Сохранить заклинания"
    L["CANCEL"] = "Отмена"
    L["ENABLE_DEBUGGER"] = "Включить отладчик"
    L["ENABLE_AUDIO_CUE"] = "Включить аудиосигнал"
    L["PROC"] = "Прок"
    L["GLOW"] = "Свечение"
    L["PIXEL"] = "Пиксель"
    L["CAST"] = "Применить"
    L["RED"] = "Красный"
    L["GREEN"] = "Зелёный"
    L["BLUE"] = "Синий"
    L["ALPHA"] = "Альфа"
    L["LINES"] = "Линии"
    L["SCALE"] = "Масштаб"
    L["FREQUENCY"] = "Частота"
    L["THICKNESS"] = "Толщина"
    L["UNSAVED_CHANGES"] = "У вас есть несохранённые изменения!"
    L["ABOUT_MOD"] = "О моде:\n\n" ..
            "• Если текущий противник является боссом, заклинания прерывания классов будут выделены вместо пользовательских выборов.\n\n" ..
            "• Отладчик предназначен в основном для разработчиков. Включение его создаст много сообщений в чате.\n\n" ..
            "• Пожалуйста, сообщайте разработчику о любых ошибках, найденных в репозитории GitHub, на CurseForge или" ..
            " WoWInterface.\n\n" ..
            "• Пожалуйста, сообщайте разработчику, если какие-либо заклинания отсутствуют в списке доступных для выбора."
elseif locale == 'ptPT' then
    L["VERSION"] = "Versão"
    L["SAVE_SPELLS"] = "Guardar Feitiços"
    L["CANCEL"] = "Cancelar"
    L["ENABLE_DEBUGGER"] = "Ativar Depurador"
    L["ENABLE_AUDIO_CUE"] = "Ativar Sinal Áudio"
    L["PROC"] = "Proc"
    L["GLOW"] = "Brilho"
    L["PIXEL"] = "Pixel"
    L["CAST"] = "Lançar"
    L["RED"] = "Vermelho"
    L["GREEN"] = "Verde"
    L["BLUE"] = "Azul"
    L["ALPHA"] = "Alfa"
    L["LINES"] = "Linhas"
    L["SCALE"] = "Escala"
    L["FREQUENCY"] = "Frequência"
    L["THICKNESS"] = "Espessura"
    L["UNSAVED_CHANGES"] = "Tens alterações não guardadas!"
    L["ABOUT_MOD"] = "Sobre o mod:\n\n" ..
            "• Se o inimigo atual for um chefe, os feitiços de interrupção de classe serão destacados em vez das seleções do utilizador.\n\n" ..
            "• O depurador é principalmente para uso dos programadores. Ativá-lo gerará muito ruído no chat.\n\n" ..
            "• Por favor, reporte qualquer erro que encontrar ao programador através do repositório GitHub, CurseForge ou" ..
            " WoWInterface.\n\n" ..
            "• Informe o programador se algum feitiço estiver em falta na lista de feitiços disponíveis para seleção."
elseif locale == 'koKR' then
    L["VERSION"] = "버전"
    L["SAVE_SPELLS"] = "주문 저장"
    L["CANCEL"] = "취소"
    L["ENABLE_DEBUGGER"] = "디버거 활성화"
    L["ENABLE_AUDIO_CUE"] = "오디오 신호 활성화"
    L["PROC"] = "발동"
    L["GLOW"] = "광채"
    L["PIXEL"] = "픽셀"
    L["CAST"] = "시전"
    L["RED"] = "빨강"
    L["GREEN"] = "초록"
    L["BLUE"] = "파랑"
    L["ALPHA"] = "투명도"
    L["LINES"] = "라인"
    L["SCALE"] = "크기"
    L["FREQUENCY"] = "빈도"
    L["THICKNESS"] = "굵기"
    L["UNSAVED_CHANGES"] = "저장되지 않은 변경 사항이 있습니다!"
    L["ABOUT_MOD"] = "모드에 대하여:\n\n" ..
            "• 현재 적이 보스라면, 사용자가 선택한 주문 대신 클래스의 차단 주문이 강조됩니다.\n\n" ..
            "• 디버거는 주로 개발자용입니다. 활성화하면 채팅에 많은 메시지가 표시됩니다.\n\n" ..
            "• GitHub 저장소, CurseForge 또는 WoWInterface에서 발견한 버그를 개발자에게 알려주십시오.\n\n" ..
            "• 선택 가능한 주문 목록에 누락된 주문이 있으면 개발자에게 알려주십시오."
elseif locale == 'esES' then
    L["VERSION"] = "Versión"
    L["SAVE_SPELLS"] = "Guardar hechizos"
    L["CANCEL"] = "Cancelar"
    L["ENABLE_DEBUGGER"] = "Habilitar depurador"
    L["ENABLE_AUDIO_CUE"] = "Habilitar señal de audio"
    L["PROC"] = "Proc"
    L["GLOW"] = "Brillo"
    L["PIXEL"] = "Píxel"
    L["CAST"] = "Lanzar"
    L["RED"] = "Rojo"
    L["GREEN"] = "Verde"
    L["BLUE"] = "Azul"
    L["ALPHA"] = "Alfa"
    L["LINES"] = "Líneas"
    L["SCALE"] = "Escala"
    L["FREQUENCY"] = "Frecuencia"
    L["THICKNESS"] = "Grosor"
    L["UNSAVED_CHANGES"] = "¡Tienes cambios sin guardar!"
    L["ABOUT_MOD"] = "Acerca del mod:\n\n" ..
            "• Si el enemigo actual es un jefe, los hechizos de interrupción de clase se resaltarán en lugar de las selecciones del usuario.\n\n" ..
            "• El depurador es principalmente para uso de desarrolladores. Activarlo generará mucho ruido en el chat.\n\n" ..
            "• Por favor, informa de cualquier error que encuentres al desarrollador en el repositorio de GitHub, CurseForge o" ..
            " WoWInterface.\n\n" ..
            "• Por favor, informa al desarrollador si faltan hechizos en la lista de hechizos disponibles para selección."
elseif (locale == 'zhTW' or locale == 'enTW') then
    L["VERSION"] = "版本"
    L["SAVE_SPELLS"] = "保存法術"
    L["CANCEL"] = "取消"
    L["ENABLE_DEBUGGER"] = "啟用除錯器"
    L["ENABLE_AUDIO_CUE"] = "啟用音效提示"
    L["PROC"] = "觸發"
    L["GLOW"] = "光暈"
    L["PIXEL"] = "像素"
    L["CAST"] = "施法"
    L["RED"] = "紅色"
    L["GREEN"] = "綠色"
    L["BLUE"] = "藍色"
    L["ALPHA"] = "透明度"
    L["LINES"] = "線條"
    L["SCALE"] = "比例"
    L["FREQUENCY"] = "頻率"
    L["THICKNESS"] = "粗細"
    L["UNSAVED_CHANGES"] = "您有未保存的更改！"
    L["ABOUT_MOD"] = "關於此模組:\n\n" ..
            "• 如果當前敵人是首領，將會高亮顯示職業的打斷法術，而不是玩家選擇的法術。\n\n" ..
            "• 除錯器主要供開發者使用。啟用後會在聊天中產生大量訊息。\n\n" ..
            "• 請向開發者報告您發現的任何錯誤，您可以透過 GitHub 倉庫、CurseForge 或 WoWInterface。\n\n" ..
            "• 如果法術列表中缺少任何可選法術，請通知開發者。"
else
    L["VERSION"] = "Version"
    L["SAVE_SPELLS"] = "Save Spells"
    L["CANCEL"] = "Cancel"
    L["ENABLE_DEBUGGER"] = "Enable Debugger"
    L["ENABLE_AUDIO_CUE"] = "Enable Audio Cue"
    L["PROC"] = "Proc"
    L["GLOW"] = "Glow"
    L["PIXEL"] = "Pixel"
    L["CAST"] = "Cast"
    L["RED"] = "Red"
    L["GREEN"] = "Green"
    L["BLUE"] = "Blue"
    L["ALPHA"] = "Alpha"
    L["LINES"] = "Lines"
    L["SCALE"] = "Scale"
    L["FREQUENCY"] = "Frequency"
    L["THICKNESS"] = "Thickness"
    L["UNSAVED_CHANGES"] = "You have unsaved changes!"
    L["ABOUT_MOD"] = "About the mod:\n\n" ..
            "• If the current mob is a boss, class interrupt spells will be highlighted instead of user selections.\n\n" ..
            "• The debugger is mainly for developer use. Enabling it will cause a lot of chat noise.\n\n" ..
            "• Please let the developer of any bugs you come across at either the GitHub repository, CurseForge or" ..
            " WoWInterface.\n\n" ..
            "• Please let the developer know if any spells are missing from the list of spells available for selection."
end


InterruptReminder_Localization = L