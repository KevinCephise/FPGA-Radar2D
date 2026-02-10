#include <stdio.h>
#include <math.h>
#include <unistd.h>
#include "system.h"
#include "io.h"
#include "altera_up_avalon_video_pixel_buffer_dma.h"

#define SCREEN_WIDTH  320
#define SCREEN_HEIGHT 240

// Centre du radar (Milieu bas)
#define XC 160
#define YC 239

// Rayon maximal d'affichage (en pixels)
#define RAYON_MAX 220

// Facteur d'échelle : 1 cm réel = X pixels
#define PIXELS_PAR_CM 2

// Couleurs (Format RGB 565)
#define COLOR_BLACK 0x0000
#define COLOR_GREEN 0x07E0
#define COLOR_RED   0xF800


#define CYCLES_PAR_CM 2900

#define SERVO_BASE     SERVOMOTEUR_AVALON_0_BASE
#define TELEMETRE_BASE TELEMETRE_AVALON_0_BASE

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif


void update_radar_slice(alt_up_pixel_buffer_dma_dev* pixel_buffer, int angle_deg, int distance_cm) {
    float rad = (float)angle_deg * M_PI / 180.0;

    // Calcul de la distance en pixels
    int dist_px = distance_cm * PIXELS_PAR_CM;

    // Si l'objet est trop loin ou hors plage, on le considère au max
    if (dist_px > RAYON_MAX) dist_px = RAYON_MAX;

    // Calcul trigonométrique des vecteurs
    double cos_val = cos(rad);
    double sin_val = sin(rad);

    // DESSIN DE LA ZONE LIBRE (VERT)
    // On part du centre (XC, YC) jusqu'à l'objet (dist_px)
    int x_obj = XC + (int)(dist_px * cos_val);
    int y_obj = YC - (int)(dist_px * sin_val);

    alt_up_pixel_buffer_dma_draw_line(pixel_buffer, XC, YC, x_obj, y_obj, COLOR_GREEN, 0);

    // DESSIN DE L'OBSTACLE (ROUGE)
    // On dessine l'obstacle seulement s'il est dans le rayon visible (< RAYON_MAX)
    if (dist_px < RAYON_MAX) {
        // On épaissit un peu le point rouge (en continuant la ligne sur quelques pixels)
        int x_red_end = XC + (int)((dist_px + 5) * cos_val);
        int y_red_end = YC - (int)((dist_px + 5) * sin_val);

        alt_up_pixel_buffer_dma_draw_line(pixel_buffer, x_obj, y_obj, x_red_end, y_red_end, COLOR_RED, 0);

        // Mise à jour de la position de départ pour la zone noire
        // La zone noire commence juste après le rouge
        x_obj = x_red_end;
        y_obj = y_red_end;
    }

    // NETTOYAGE DE L'ARRIERE PLAN (NOIR)
    int x_max = XC + (int)(RAYON_MAX * cos_val);
    int y_max = YC - (int)(RAYON_MAX * sin_val);

    // On trace du bout de l'obstacle jusqu'au max
    alt_up_pixel_buffer_dma_draw_line(pixel_buffer, x_obj, y_obj, x_max, y_max, COLOR_BLACK, 0);
}




int main() {
    // Ouverture du Buffer Vidéo
    alt_up_pixel_buffer_dma_dev *pixel_buffer;
    pixel_buffer = alt_up_pixel_buffer_dma_open_dev("/dev/VGA_Subsystem_VGA_Pixel_DMA");

    if (pixel_buffer == NULL) {
        printf("Erreur : Impossible d'ouvrir le buffer vidéo.\n");
        pixel_buffer = alt_up_pixel_buffer_dma_open_dev("VGA_Subsystem_VGA_Pixel_DMA");
        if (pixel_buffer == NULL) return -1;
    }

    // Nettoyage initial de l'écran (Tout noir)
    alt_up_pixel_buffer_dma_clear_screen(pixel_buffer, 0);

    printf("Radar 2D - Mode Cartographie\n");

    int angle = 0;
    int servo_cmd = 0;
    int raw_dist = 0;
    int dist_cm = 0;

    while (1) {
    	// Phase 1 : 0° à 180°
        for (angle = 0; angle <= 180; angle++) {
            servo_cmd = (angle * 255) / 180;
            IOWR(SERVO_BASE, 0, servo_cmd);

            usleep(60000);

            raw_dist = IORD(TELEMETRE_BASE, 0);
            if (CYCLES_PAR_CM > 0) dist_cm = raw_dist / CYCLES_PAR_CM;
            else dist_cm = raw_dist;

            update_radar_slice(pixel_buffer, angle, dist_cm);
        }

        // Phase 2 : 180° à 0°
        for (angle = 180; angle >= 0; angle--) {
            servo_cmd = (angle * 255) / 180;
            IOWR(SERVO_BASE, 0, servo_cmd);

            usleep(60000);

            raw_dist = IORD(TELEMETRE_BASE, 0);
            if (CYCLES_PAR_CM > 0) dist_cm = raw_dist / CYCLES_PAR_CM;
            else dist_cm = raw_dist;

            update_radar_slice(pixel_buffer, angle, dist_cm);
        }
    }
    return 0;
}

