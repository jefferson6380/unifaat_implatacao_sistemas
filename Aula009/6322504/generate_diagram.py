from PIL import Image, ImageDraw, ImageFont
import os

W, H = 900, 620
img = Image.new("RGB", (W, H), "#0d1117")
d = ImageDraw.Draw(img)

def rect(x, y, w, h, fill, outline, radius=8):
    d.rounded_rectangle([x, y, x+w, y+h], radius=radius, fill=fill, outline=outline, width=2)

def text(x, y, msg, color="#c9d1d9", size=14, anchor="mm"):
    try:
        font = ImageFont.truetype("arial.ttf", size)
    except:
        font = ImageFont.load_default()
    d.text((x, y), msg, fill=color, font=font, anchor=anchor)

# Titulo
text(W//2, 30, "TF09 - Arquitetura AWS | Luan Teixeira (RA: 6322504)", "#58a6ff", 16)

# Internet
rect(360, 55, 180, 40, "#21262d", "#58a6ff")
text(450, 75, "Internet", "#c9d1d9", 13)

# Seta internet -> IGW
d.line([(450, 95), (450, 125)], fill="#58a6ff", width=2)
d.polygon([(445,125),(455,125),(450,133)], fill="#58a6ff")

# IGW
rect(330, 133, 240, 40, "#1f2937", "#f59e0b")
text(450, 153, "Internet Gateway", "#f59e0b", 13)

# Seta IGW -> VPC
d.line([(450, 173), (450, 200)], fill="#58a6ff", width=2)
d.polygon([(445,200),(455,200),(450,208)], fill="#58a6ff")

# VPC box
rect(50, 205, 800, 360, "#161b22", "#30363d", radius=12)
text(130, 225, "VPC: 10.0.0.0/16  |  us-east-1", "#8b949e", 12, anchor="lm")

# Subnet Publica
rect(70, 240, 360, 160, "#0d2137", "#3b82f6", radius=8)
text(250, 258, "Subnet Publica - 10.0.1.0/24", "#3b82f6", 12)

# Web Server box
rect(90, 270, 320, 110, "#1e3a5f", "#58a6ff", radius=6)
text(250, 292, "EC2: TF09-WebServer", "#e6edf3", 13)
text(250, 312, "t3.micro | Amazon Linux 2", "#8b949e", 11)
text(250, 330, "IP Publico: 18.215.126.218", "#58a6ff", 11)
text(250, 350, "Docker: Nginx :80 + Node.js :3000", "#8b949e", 11)
text(250, 368, "SG: portas 22 / 80 / 443 / 3000", "#f59e0b", 10)

# Subnet Privada
rect(470, 240, 360, 160, "#1a1f0d", "#22c55e", radius=8)
text(650, 258, "Subnet Privada - 10.0.2.0/24", "#22c55e", 12)

# Database box
rect(490, 270, 320, 110, "#1a2e1a", "#22c55e", radius=6)
text(650, 292, "EC2: TF09-Database", "#e6edf3", 13)
text(650, 312, "t3.micro | Amazon Linux 2", "#8b949e", 11)
text(650, 330, "IP Privado: 10.0.2.51", "#22c55e", 11)
text(650, 350, "MySQL 8 - porta 3306", "#8b949e", 11)
text(650, 368, "SG: acesso restrito ao Web SG", "#f59e0b", 10)

# Seta Web -> DB
d.line([(410, 325), (490, 325)], fill="#f59e0b", width=2)
d.polygon([(488,320),(498,325),(488,330)], fill="#f59e0b")
text(450, 312, "MySQL", "#f59e0b", 10)
text(450, 326, ":3306", "#f59e0b", 10)

# Route Table
rect(70, 420, 760, 40, "#21262d", "#6b7280", radius=6)
text(450, 440, "Route Table: 0.0.0.0/0 -> IGW  |  10.0.0.0/16 -> local", "#8b949e", 12)

# Key Pair
rect(70, 475, 200, 35, "#21262d", "#a78bfa", radius=6)
text(170, 492, "Key Pair SSH", "#a78bfa", 12)

# Security Groups legenda
rect(285, 475, 280, 35, "#21262d", "#f59e0b", radius=6)
text(425, 492, "Security Groups (menor privilegio)", "#f59e0b", 11)

# Free Tier
rect(580, 475, 250, 35, "#21262d", "#22c55e", radius=6)
text(705, 492, "Free Tier: $0,00/mes", "#22c55e", 12)

# Rodape
text(W//2, 600, "UniFAAT | Implementacao de Sistemas | 2026", "#484f58", 11)

out = r"C:\Users\luuan\OneDrive\Desktop\ale\unifaat_implatacao_sistemas\Aula009\6322504\infrastructure\infrastructure-diagram.png"
img.save(out, "PNG")
print(f"Diagrama salvo em: {out}")
