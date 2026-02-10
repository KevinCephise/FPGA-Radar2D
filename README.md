# 📡 Radar 2D - SoC-FPGA & Télémètre Ultrason

Ce projet consiste en la conception et l’implémentation d’un système de cartographie **2D (Radar)** sur une carte **DE10-Lite**.

Le système utilise un **télémètre à ultrasons HC-SR04** monté sur un **servomoteur** afin de scanner l’environnement sur un angle de **180°**.

---

## 🚀 Objectifs du Projet

- Conception d’**IPs matérielles personnalisées en VHDL**  
  (Télémètre, Servomoteur)
- Intégration dans un **système SoC** via le **bus Avalon** avec un processeur **Nios II**
- Développement d’une **application logicielle en C** pour la gestion du balayage et le traitement des données
- **Visualisation en temps réel** via un écran **VGA**

---

## 🛠️ Architecture du Système

### 1️⃣ Partie Matérielle (Hardware – VHDL)

- **IP Télémètre HC-SR04**  
  - Génération du signal *Trigger* (impulsion de 10 µs)  
  - Mesure de la durée de l’impulsion *Echo*  
  - Calcul de la distance (de 2 cm à 400 cm)

- **IP Servomoteur**  
  - Génération d’un signal PWM  
  - Période : 20 ms  
  - Largeur d’impulsion :
    - 0,5 ms → 0°
    - 2,5 ms → 180°

- **Interface Avalon**  
  - Chaque IP est encapsulée pour être pilotée par le processeur **Nios II**  
  - Accès via registres `readdata` et `writedata`

---

### 2️⃣ Partie Logicielle (Software – C)

- Algorithme de **balayage automatique** du servomoteur
- Acquisition **synchronisée** des distances via l’IP Télémètre
- Formatage et transmission des **coordonnées polaires** :
  - Angle
  - Distance

---

## 📊 Spécifications du Capteur HC-SR04

| Paramètre           | Valeur            |
|---------------------|-------------------|
| Plage de mesure     | 2 cm à 400 cm     |
| Résolution          | 0,3 cm            |
| Angle efficace      | 15°               |
| Fréquence ultrasons | 40 kHz            |

---

## 📁 Structure du Dépôt

```text
/
├── hw/     # Sources VHDL, top-level et projet Quartus
├── sw/     # Code source C pour Nios II (SBT)
├── simu/    # Bancs de test (Testbenchs) et scripts ModelSim
└── docs/   # Documentation technique et rapport de projet

```
---

## 🔧 Installation et Utilisation

### 🧩 Matériel

- Connexion du **HC-SR04** et du **servomoteur** aux GPIO de la **DE10-Lite**
- Alimentation : **5V / GND**
- Trigger : **PIN W10**
- Echo : **PIN W9**
- Servo : **PIN V10**

### ⚙️ Quartus

1. Ouvrir le projet dans **Quartus Prime 18.1**
2. Générer le système avec **Platform Designer**
3. Compiler et programmer le **bitstream** sur la carte

### 🖥️ Nios II

1. Compiler le code C dans **Nios II Software Build Tools (SBT)**
2. Charger le programme sur la carte **DE10-Lite**

### 📺 Visualisation

- Affichage sur **écran VGA**


## 🧑‍💻 Auteurs

**CEPHISE Kevin** & **Sarra SOLTAN**
Étudiant en Électronique / Systèmes Embarqués  

Projet encadré par **Yann DOUZE**
