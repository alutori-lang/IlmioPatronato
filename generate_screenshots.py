from PIL import Image, ImageDraw, ImageFont
import os

W, H = 1080, 1920
OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

# Colors from the app
BG = (238, 242, 247)
HEADER_TOP = (10, 22, 40)
HEADER_MID = (13, 45, 94)
HEADER_BOT = (20, 61, 122)
PRIMARY = (21, 101, 192)
WHITE = (255, 255, 255)
TEXT_DARK = (26, 26, 26)
TEXT_MED = (120, 120, 120)
TEXT_LIGHT = (160, 160, 160)
ORANGE = (230, 81, 0)
GREEN = (46, 125, 50)
PURPLE = (106, 27, 154)
RED = (211, 47, 47)
AMBER = (255, 143, 0)
CARD_SHADOW = (220, 225, 230)

try:
    font_bold = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf', 42)
    font_title = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf', 36)
    font_med = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 30)
    font_small = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 26)
    font_tiny = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 22)
    font_header = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf', 48)
    font_big = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf', 56)
    font_stat = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf', 44)
except:
    font_bold = font_title = font_med = font_small = font_tiny = font_header = font_big = font_stat = ImageFont.load_default()

def draw_header_gradient(draw, h=200):
    for y in range(h):
        ratio = y / h
        r = int(HEADER_TOP[0] + (HEADER_BOT[0] - HEADER_TOP[0]) * ratio)
        g = int(HEADER_TOP[1] + (HEADER_BOT[1] - HEADER_TOP[1]) * ratio)
        b = int(HEADER_TOP[2] + (HEADER_BOT[2] - HEADER_TOP[2]) * ratio)
        draw.line([(0, y), (W, y)], fill=(r, g, b))

def draw_rounded_rect(draw, xy, radius, fill, outline=None):
    x0, y0, x1, y1 = xy
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline)

def draw_card(draw, x, y, w, h, radius=28):
    draw_rounded_rect(draw, (x+4, y+4, x+w+4, y+h+4), radius, CARD_SHADOW)
    draw_rounded_rect(draw, (x, y, x+w, y+h), radius, WHITE)

def draw_icon_circle(draw, cx, cy, r, color, bg_alpha=0.12):
    bg = tuple(int(c + (255 - c) * (1 - bg_alpha)) for c in color)
    draw.rounded_rectangle((cx-r, cy-r, cx+r, cy+r), radius=r//2, fill=bg)

def draw_status_bar(draw):
    draw.text((40, 20), "12:00", fill=WHITE, font=font_tiny)
    # Battery, wifi icons as simple shapes
    draw.rectangle((940, 22, 980, 42), fill=WHITE)
    draw.rectangle((980, 28, 988, 42), fill=WHITE)
    draw.ellipse((890, 22, 920, 42), fill=WHITE)

def draw_nav_bar(draw, active=0):
    bar_y = H - 140
    draw.rectangle((0, bar_y, W, H), fill=WHITE)
    draw.line([(0, bar_y), (W, bar_y)], fill=(230, 230, 230), width=2)

    labels = ['Home', 'Guide', 'Bonus', 'Strumenti', 'Profilo']
    icons_y = bar_y + 25
    label_y = bar_y + 80

    for i, label in enumerate(labels):
        cx = 108 + i * 216
        color = PRIMARY if i == active else TEXT_LIGHT
        # Simple icon placeholder
        draw.rounded_rectangle((cx-22, icons_y, cx+22, icons_y+44), radius=8, fill=color)
        tw = draw.textlength(label, font=font_tiny)
        draw.text((cx - tw/2, label_y), label, fill=color, font=font_tiny)
        if i == active:
            draw.rectangle((cx-30, bar_y, cx+30, bar_y+6), fill=PRIMARY)


# ═══════════════════════════════════════════════════
# SCREENSHOT 1: HOME SCREEN
# ═══════════════════════════════════════════════════
def screenshot_home():
    img = Image.new('RGB', (W, H), BG)
    draw = ImageDraw.Draw(img)

    draw_header_gradient(draw, 180)
    draw_status_bar(draw)

    # Shield icon
    draw.rounded_rectangle((40, 80, 90, 130), radius=14, fill=PRIMARY)
    # App name
    draw.text((110, 80), "IL MIO PATRONATO", fill=WHITE, font=font_bold)
    draw.text((110, 130), "Assistenza Immigrazione", fill=(170, 190, 220), font=font_small)

    # Banner card
    y = 200
    for i in range(200):
        ratio = i / 200
        r = int(13 + (21-13) * ratio)
        g = int(45 + (80-45) * ratio)
        b = int(120 + (180-120) * ratio)
        draw.line([(40, y+i), (W-40, y+i)], fill=(r, g, b))
    draw.rounded_rectangle((40, y, W-40, y+200), radius=28, outline=(20, 60, 120), width=3)
    draw.text((80, y+30), "Benvenuto su", fill=WHITE, font=font_med)
    draw.text((80, y+70), "Il Mio Patronato", fill=WHITE, font=font_big)
    draw.text((80, y+140), "Pratiche, Bonus e Servizi", fill=(170, 200, 255), font=font_small)

    # Agevolazione del giorno
    y = 430
    for i in range(120):
        ratio = i / 120
        r = int(21 + (13-21) * ratio)
        g = int(101 + (71-101) * ratio)
        b = int(192 + (161-192) * ratio)
        draw.line([(40, y+i), (W-40, y+i)], fill=(r, g, b))
    draw.rounded_rectangle((40, y, W-40, y+120), radius=24, outline=PRIMARY, width=2)
    draw.rounded_rectangle((60, y+15, 150, y+105), radius=16, fill=(255, 255, 255, 50))
    draw.text((72, y+15), "AGEVOLAZIONE", fill=AMBER, font=font_tiny)
    draw.text((72, y+45), "DEL GIORNO", fill=AMBER, font=font_tiny)
    draw.text((170, y+35), "NASpI - Indennità", fill=WHITE, font=font_title)
    draw.text((170, y+80), "Fino a €1.470/mese", fill=(255, 200, 100), font=font_small)

    # Section title
    y = 580
    draw.text((50, y), "Cosa vuoi fare?", fill=TEXT_DARK, font=font_title)

    # 4 Service cards grid
    y = 640
    card_w = (W - 120) // 2
    card_h = 200

    cards = [
        (ORANGE, "Agevolazioni", "53 bonus & diritti"),
        (PURPLE, "Guide", "18 guide step-by-step"),
        (GREEN, "Strumenti", "20+ calcolatori & tools"),
        (PRIMARY, "Calcola ISEE", "Formula ufficiale"),
    ]

    for i, (color, title, sub) in enumerate(cards):
        cx = 40 + (i % 2) * (card_w + 30)
        cy = y + (i // 2) * (card_h + 20)
        draw_card(draw, cx, cy, card_w, card_h)
        draw_icon_circle(draw, cx + 70, cy + 70, 40, color)
        draw.text((cx + 30, cy + 125), title, fill=TEXT_DARK, font=font_med)
        draw.text((cx + 30, cy + 160), sub, fill=TEXT_MED, font=font_tiny)

    # Stats row
    y = 1100
    draw_card(draw, 40, y, W-80, 100)
    stats = [("53", "BONUS"), ("18", "GUIDE"), ("14", "CALCOLATORI"), ("6", "PDF")]
    for i, (val, label) in enumerate(stats):
        sx = 100 + i * 240
        draw.text((sx, y+15), val, fill=PRIMARY, font=font_stat)
        tw = draw.textlength(label, font=font_tiny)
        draw.text((sx, y+65), label, fill=TEXT_LIGHT, font=font_tiny)

    # Novità section
    y = 1240
    draw.text((50, y), "Novità Agevolazioni 2025", fill=TEXT_DARK, font=font_title)

    y = 1300
    novita = [
        ("ADI - Assegno Inclusione", "Fino a €780/mese"),
        ("Bonus Asilo Nido 2025", "Fino a €3.600/anno"),
        ("Carta Dedicata a Te", "€500 una tantum"),
    ]
    for i, (title, amount) in enumerate(novita):
        ny = y + i * 100
        draw_card(draw, 40, ny, W-80, 85)
        draw.rounded_rectangle((65, ny+20, 110, ny+65), radius=12, fill=(255, 230, 230))
        draw.text((75, ny+25), "N", fill=RED, font=font_med)
        draw.text((130, ny+18), title, fill=TEXT_DARK, font=font_med)
        draw.text((130, ny+55), amount, fill=GREEN, font=font_small)

    draw_nav_bar(draw, 0)
    img.save(os.path.join(OUTPUT_DIR, 'screenshot_1_home.png'))
    print("1/6 Home")


# ═══════════════════════════════════════════════════
# SCREENSHOT 2: AGEVOLAZIONI
# ═══════════════════════════════════════════════════
def screenshot_agevolazioni():
    img = Image.new('RGB', (W, H), BG)
    draw = ImageDraw.Draw(img)

    draw_header_gradient(draw, 180)
    draw_status_bar(draw)

    # Header
    draw.rounded_rectangle((40, 80, 90, 130), radius=14, fill=ORANGE)
    draw.text((110, 80), "AGEVOLAZIONI", fill=WHITE, font=font_bold)
    draw.text((110, 130), "Bonus e diritti del Governo", fill=(170, 190, 220), font=font_small)
    draw.rounded_rectangle((900, 85, 1000, 130), radius=16, fill=(255, 255, 255, 40))
    draw.text((925, 90), "53", fill=WHITE, font=font_title)

    # Search bar
    y = 200
    draw_card(draw, 40, y, W-80, 80)
    draw.text((90, y+22), "Cerca agevolazione...", fill=TEXT_LIGHT, font=font_med)

    # Category chips
    y = 310
    cats = [("Lavoro", PRIMARY), ("Casa", GREEN), ("Famiglia", PURPLE), ("Salute", RED), ("Studio", ORANGE)]
    cx = 40
    for name, color in cats:
        tw = int(draw.textlength(name, font=font_small)) + 40
        draw.rounded_rectangle((cx, y, cx+tw, y+50), radius=25, fill=color)
        draw.text((cx+20, y+10), name, fill=WHITE, font=font_small)
        cx += tw + 15

    # Agevolazione del giorno
    y = 390
    for i in range(140):
        ratio = i / 140
        r = int(21 + (13-21) * ratio)
        g = int(101 + (71-101) * ratio)
        b = int(192 + (161-192) * ratio)
        draw.line([(40, y+i), (W-40, y+i)], fill=(r, g, b))
    draw.rounded_rectangle((40, y, W-40, y+140), radius=24, outline=PRIMARY, width=2)
    draw.text((80, y+15), "AGEVOLAZIONE DEL GIORNO", fill=AMBER, font=font_tiny)
    draw.text((80, y+50), "NASpI - Indennità Disoccupazione", fill=WHITE, font=font_med)
    draw.text((80, y+90), "Perdita involontaria del lavoro", fill=(200, 210, 230), font=font_small)
    draw.text((80, y+115), "Fino a €1.470/mese", fill=(255, 200, 100), font=font_small)

    # List
    y = 570
    draw.text((50, y), "Tutte le Agevolazioni (53)", fill=TEXT_DARK, font=font_title)

    agevolazioni = [
        ("NASpI", "Indennità di disoccupazione per lavoratori", "Lavoro", "Fino a €1.470/mese", PRIMARY),
        ("DIS-COLL", "Indennità per collaboratori coordinati", "Lavoro", "Proporzionale", PRIMARY),
        ("Assegno Unico", "Assegno universale per figli a carico", "Famiglia", "€54-€189/figlio", PURPLE),
        ("ADI", "Assegno di Inclusione per nuclei fragili", "Famiglia", "Fino a €780/mese", PURPLE),
        ("Bonus Affitto", "Contributo per il canone di locazione", "Casa", "Fino a €2.000", GREEN),
        ("Bonus Luce e Gas", "Sconto in bolletta per famiglie ISEE basso", "Casa", "€150-€700/anno", GREEN),
        ("Bonus Trasporti", "Contributo per abbonamenti trasporto", "Giovani", "Fino a €60", ORANGE),
        ("Bonus Psicologo", "Contributo per supporto psicologico", "Salute", "Fino a €1.500", RED),
    ]

    y = 630
    for title, desc, cat, amount, color in agevolazioni:
        if y > 1650: break
        draw_card(draw, 40, y, W-80, 130)
        draw_icon_circle(draw, 100, y+65, 35, color)
        draw.text((155, y+15), title, fill=TEXT_DARK, font=font_med)
        draw.text((155, y+50), desc, fill=TEXT_MED, font=font_tiny)
        # Category badge
        draw.rounded_rectangle((155, y+85, 155+len(cat)*14+20, y+110), radius=6, fill=(*color, 30))
        draw.text((165, y+86), cat, fill=color, font=font_tiny)
        # Amount
        draw.text((350, y+86), amount, fill=GREEN, font=font_tiny)
        y += 145

    draw_nav_bar(draw, 2)
    img.save(os.path.join(OUTPUT_DIR, 'screenshot_2_agevolazioni.png'))
    print("2/6 Agevolazioni")


# ═══════════════════════════════════════════════════
# SCREENSHOT 3: GUIDE
# ═══════════════════════════════════════════════════
def screenshot_guide():
    img = Image.new('RGB', (W, H), BG)
    draw = ImageDraw.Draw(img)

    draw_header_gradient(draw, 180)
    draw_status_bar(draw)

    draw.text((60, 90), "Guide Pratiche", fill=WHITE, font=font_header)

    # Search bar
    y = 200
    draw_card(draw, 40, y, W-80, 80)
    draw.text((90, y+22), "Cerca una guida...", fill=TEXT_LIGHT, font=font_med)

    # Category chips
    y = 310
    cats = ["Tutti", "Documenti", "Lavoro", "Cittadinanza", "Sanità"]
    cx = 40
    for i, name in enumerate(cats):
        tw = int(draw.textlength(name, font=font_small)) + 40
        if i == 0:
            draw.rounded_rectangle((cx, y, cx+tw, y+50), radius=25, fill=PRIMARY)
            draw.text((cx+20, y+10), name, fill=WHITE, font=font_small)
        else:
            draw.rounded_rectangle((cx, y, cx+tw, y+50), radius=25, outline=(200,200,200), width=2)
            draw.text((cx+20, y+10), name, fill=TEXT_MED, font=font_small)
        cx += tw + 12

    draw.text((50, y+70), "18 guide disponibili", fill=TEXT_LIGHT, font=font_small)

    # Guide list
    y = 440
    guide = [
        ("Permesso di Soggiorno", "Primo rilascio - documenti e procedura completa", (33, 150, 243), "45 min", "€100-200"),
        ("Rinnovo Permesso", "Come rinnovare il PdS in scadenza", PRIMARY, "30 min", "€80-130"),
        ("Ricongiungimento Familiare", "Procedura per ricongiungere la famiglia", PURPLE, "3-6 mesi", "€200+"),
        ("Cittadinanza Italiana", "Requisiti e iter per la cittadinanza", GREEN, "2-4 anni", "€250"),
        ("Codice Fiscale", "Come ottenere o recuperare il CF", ORANGE, "15 min", "Gratuito"),
        ("SPID / CIE", "Identità digitale - come attivarla", (0, 121, 107), "20 min", "Gratuito"),
        ("Contratto di Lavoro", "Tipi di contratto e diritti del lavoratore", RED, "Lettura", "-"),
        ("Iscrizione SSN", "Come iscriversi al Sistema Sanitario Nazionale", (233, 30, 99), "30 min", "Gratuito"),
    ]

    for title, desc, color, time, cost in guide:
        if y > 1650: break
        draw_card(draw, 40, y, W-80, 120)
        draw_icon_circle(draw, 105, y+60, 38, color)
        draw.text((160, y+20), title, fill=TEXT_DARK, font=font_med)
        draw.text((160, y+58), desc, fill=TEXT_MED, font=font_tiny)
        draw.text((160, y+88), f"⏱ {time}  •  💰 {cost}", fill=TEXT_LIGHT, font=font_tiny)
        draw.text((W-110, y+50), ">", fill=TEXT_LIGHT, font=font_title)
        y += 135

    draw_nav_bar(draw, 1)
    img.save(os.path.join(OUTPUT_DIR, 'screenshot_3_guide.png'))
    print("3/6 Guide")


# ═══════════════════════════════════════════════════
# SCREENSHOT 4: CALCOLATORE ISEE
# ═══════════════════════════════════════════════════
def screenshot_isee():
    img = Image.new('RGB', (W, H), BG)
    draw = ImageDraw.Draw(img)

    draw_header_gradient(draw, 180)
    draw_status_bar(draw)

    # Back arrow + title
    draw.rounded_rectangle((40, 85, 85, 130), radius=12, fill=(255,255,255,40))
    draw.text((50, 88), "<", fill=WHITE, font=font_title)
    draw.text((110, 85), "Calcola ISEE", fill=WHITE, font=font_header)
    draw.text((110, 140), "Formula ufficiale DPCM 159/2013", fill=(170, 190, 220), font=font_tiny)

    # Form fields
    y = 210
    fields = [
        ("Numero componenti nucleo", "4"),
        ("Reddito complessivo annuo (€)", "28.000"),
        ("Patrimonio mobiliare (€)", "12.500"),
        ("Patrimonio immobiliare (€)", "85.000"),
        ("Canone affitto annuo (€)", "6.000"),
    ]

    for label, value in fields:
        draw_card(draw, 40, y, W-80, 110)
        draw.text((70, y+15), label, fill=TEXT_MED, font=font_small)
        draw.rounded_rectangle((70, y+55, W-110, y+90), radius=10, outline=(200,200,200), width=2)
        draw.text((90, y+58), value, fill=TEXT_DARK, font=font_med)
        y += 125

    # Checkboxes
    y += 10
    draw_card(draw, 40, y, W-80, 120)
    draw.text((70, y+15), "Condizioni speciali:", fill=TEXT_MED, font=font_small)
    # Checked
    draw.rounded_rectangle((70, y+55, 100, y+85), radius=6, fill=PRIMARY)
    draw.text((78, y+55), "✓", fill=WHITE, font=font_small)
    draw.text((115, y+58), "Nucleo con minori", fill=TEXT_DARK, font=font_small)
    # Unchecked
    draw.rounded_rectangle((70, y+90, 100, y+115), radius=6, outline=(200,200,200), width=2)
    draw.text((115, y+90), "Componente con disabilità", fill=TEXT_DARK, font=font_small)

    y += 145

    # Calculate button
    for i in range(70):
        ratio = i / 70
        r = int(21 + (30-21) * ratio)
        g = int(101 + (136-101) * ratio)
        b = int(192 + (229-192) * ratio)
        draw.line([(40, y+i), (W-40, y+i)], fill=(r, g, b))
    draw.rounded_rectangle((40, y, W-40, y+70), radius=18, outline=PRIMARY, width=2)
    tw = draw.textlength("CALCOLA ISEE", font=font_bold)
    draw.text(((W-tw)/2, y+12), "CALCOLA ISEE", fill=WHITE, font=font_bold)

    # Result card
    y += 100
    draw.rounded_rectangle((40, y, W-40, y+220), radius=24, fill=PRIMARY)
    draw.text((80, y+20), "IL TUO ISEE STIMATO", fill=(170, 200, 255), font=font_small)
    tw = draw.textlength("€ 15.842,37", font=font_big)
    draw.text(((W-tw)/2, y+60), "€ 15.842,37", fill=WHITE, font=font_big)

    draw.line([(80, y+130), (W-80, y+130)], fill=(50, 120, 210), width=2)
    draw.text((80, y+145), "Fascia: MEDIA", fill=(170, 200, 255), font=font_small)
    draw.text((80, y+180), "Hai accesso a: Bonus Luce, Bonus Gas,", fill=(200, 220, 255), font=font_tiny)

    draw_nav_bar(draw, 3)
    img.save(os.path.join(OUTPUT_DIR, 'screenshot_4_isee.png'))
    print("4/6 ISEE")


# ═══════════════════════════════════════════════════
# SCREENSHOT 5: STRUMENTI
# ═══════════════════════════════════════════════════
def screenshot_strumenti():
    img = Image.new('RGB', (W, H), BG)
    draw = ImageDraw.Draw(img)

    draw_header_gradient(draw, 180)
    draw_status_bar(draw)

    draw.rounded_rectangle((40, 80, 90, 130), radius=14, fill=PRIMARY)
    draw.text((110, 80), "STRUMENTI", fill=WHITE, font=font_bold)
    draw.text((110, 130), "Calcolatori, generatori e servizi", fill=(170, 190, 220), font=font_small)

    # Top tools (horizontal)
    draw.text((50, 200), "Più Usati", fill=TEXT_DARK, font=font_title)

    y = 250
    top_tools = [
        ("ISEE", PURPLE), ("730", (0, 121, 107)), ("Cod.Fisc", (63, 81, 181)),
        ("Stipendio", GREEN), ("Moduli", PRIMARY), ("Prenota", ORANGE)
    ]
    for i, (label, color) in enumerate(top_tools):
        cx = 80 + i * 170
        draw_icon_circle(draw, cx, y+30, 38, color)
        tw = draw.textlength(label, font=font_tiny)
        draw.text((cx - tw/2, y+80), label, fill=TEXT_DARK, font=font_tiny)

    # Calcolatori section
    y = 380
    draw.text((50, y), "Calcolatori", fill=TEXT_DARK, font=font_title)
    draw.text((750, y+5), "14 totali", fill=PRIMARY, font=font_small)

    # 3x3 grid
    y = 440
    calc_tools = [
        ("Cittadinanza", GREEN), ("Costo Permesso", PRIMARY), ("ISEE", PURPLE),
        ("730 / IRPEF", (0,121,107)), ("Cod. Fiscale", (63,81,181)), ("Stipendio", GREEN),
        ("NASpI", RED), ("Tutti (14)", TEXT_MED),
    ]

    card_w = (W - 120) // 3
    card_h = 160
    for i, (label, color) in enumerate(calc_tools):
        if i >= 8: break
        cx = 40 + (i % 3) * (card_w + 15)
        cy = y + (i // 3) * (card_h + 15)
        draw_card(draw, cx, cy, card_w, card_h)
        draw_icon_circle(draw, cx + card_w//2, cy + 55, 32, color)
        tw = draw.textlength(label, font=font_tiny)
        draw.text((cx + (card_w - tw)/2, cy + 105), label, fill=TEXT_DARK, font=font_tiny)

    # Generatori & Tools
    y = 970
    draw.text((50, y), "Generatori & Tools", fill=TEXT_DARK, font=font_title)

    tools = [
        ("Documento Wallet", "Salva documenti con alert scadenza", PRIMARY, "NUOVO"),
        ("Quiz Cittadinanza", "218 domande per il test B1 + cultura", GREEN, "218 Q"),
        ("CV Europass", "Crea CV professionale in PDF", PURPLE, "PDF"),
        ("Busta Paga Spiegata", "Ogni voce spiegata in modo semplice", ORANGE, None),
        ("Generatore Delega", "Crea delega formale in PDF", (0,121,107), "PDF"),
    ]

    y = 1030
    for title, desc, color, badge in tools:
        if y > 1650: break
        draw_card(draw, 40, y, W-80, 100)
        draw_icon_circle(draw, 100, y+50, 30, color)
        draw.text((150, y+18), title, fill=TEXT_DARK, font=font_med)
        if badge:
            bx = 150 + int(draw.textlength(title, font=font_med)) + 15
            draw.rounded_rectangle((bx, y+20, bx+len(badge)*13+16, y+45), radius=8, fill=(*color, 30))
            draw.text((bx+8, y+21), badge, fill=color, font=font_tiny)
        draw.text((150, y+58), desc, fill=TEXT_MED, font=font_tiny)
        y += 115

    draw_nav_bar(draw, 3)
    img.save(os.path.join(OUTPUT_DIR, 'screenshot_5_strumenti.png'))
    print("5/6 Strumenti")


# ═══════════════════════════════════════════════════
# SCREENSHOT 6: COMPILATORE MODULI
# ═══════════════════════════════════════════════════
def screenshot_compilatore():
    img = Image.new('RGB', (W, H), BG)
    draw = ImageDraw.Draw(img)

    draw_header_gradient(draw, 180)
    draw_status_bar(draw)

    draw.rounded_rectangle((40, 85, 85, 130), radius=12, fill=(255,255,255,40))
    draw.text((50, 88), "<", fill=WHITE, font=font_title)
    draw.text((110, 85), "Compila Moduli", fill=WHITE, font=font_header)
    draw.text((110, 140), "6 moduli ufficiali pronti", fill=(170, 190, 220), font=font_tiny)

    # Moduli list
    y = 210
    moduli = [
        ("Dichiarazione di Ospitalità", "Modulo per ospitare un cittadino straniero", PRIMARY, "Questura"),
        ("Richiesta Permesso Soggiorno", "Kit postale per il permesso di soggiorno", ORANGE, "Poste/Questura"),
        ("Dichiarazione di Residenza", "Cambio residenza o nuova iscrizione", GREEN, "Comune"),
        ("Richiesta ISEE", "Dichiarazione Sostitutiva Unica (DSU)", PURPLE, "CAF/INPS"),
        ("Domanda Assegno Unico", "Richiesta assegno universale figli", RED, "INPS"),
        ("Cessione Fabbricato", "Comunicazione cessione di immobile", (0,121,107), "Questura"),
    ]

    for title, desc, color, ente in moduli:
        draw_card(draw, 40, y, W-80, 150)
        draw_icon_circle(draw, 105, y+50, 38, color)
        draw.text((165, y+15), title, fill=TEXT_DARK, font=font_med)
        draw.text((165, y+55), desc, fill=TEXT_MED, font=font_tiny)
        # Ente badge
        draw.rounded_rectangle((165, y+90, 165+len(ente)*13+20, y+115), radius=8, fill=(*color, 30))
        draw.text((175, y+91), ente, fill=color, font=font_tiny)
        # Compile button
        bw = 150
        bx = W - 80 - bw - 20
        draw.rounded_rectangle((bx, y+90, bx+bw, y+125), radius=14, fill=color)
        tw = draw.textlength("Compila", font=font_small)
        draw.text((bx + (bw-tw)/2, y+92), "Compila", fill=WHITE, font=font_small)
        y += 170

    # Info box at bottom
    y = 1250
    if y < 1650:
        draw_card(draw, 40, y, W-80, 120)
        draw.text((70, y+15), "Come funziona?", fill=TEXT_DARK, font=font_med)
        draw.text((70, y+55), "1. Scegli il modulo  2. Compila i campi", fill=TEXT_MED, font=font_tiny)
        draw.text((70, y+85), "3. Genera PDF  4. Condividi o stampa", fill=TEXT_MED, font=font_tiny)

    draw_nav_bar(draw, 3)
    img.save(os.path.join(OUTPUT_DIR, 'screenshot_6_compilatore.png'))
    print("6/6 Compilatore")


# Generate all
screenshot_home()
screenshot_agevolazioni()
screenshot_guide()
screenshot_isee()
screenshot_strumenti()
screenshot_compilatore()
print(f"\nTutti gli screenshot salvati in: {OUTPUT_DIR}")
