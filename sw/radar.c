#include <stdio.h>
#include <unistd.h>
#include "system.h"
#include "io.h"


#define CYCLES_PAR_CM 5800 

int main()
{
    printf("--- Radar 2D : Mode Scan avec Conversion C ---\n");

    int angle_deg = 0;
    int servo_cmd = 0;
    int raw_value = 0;   // Valeur brute (nombre de ticks)
    int distance_cm = 0; // Valeur convertie

    while(1)
    {
        // ==========================================
        // Phase 1 : Aller (0° vers 180°)
        // ==========================================
        printf(">> Scan vers la gauche (0 -> 180)\n");
        
        for (angle_deg = 0; angle_deg <= 180; angle_deg++)
        {
            servo_cmd = (angle_deg * 255) / 180;
            IOWR(SERVOMOTEUR_AVALON_0_BASE, 0, servo_cmd);

            usleep(100000); 

            raw_value = IORD(TELEMETRE_AVALON_0_BASE, 0);

            // Conversion logicielle en cm
            distance_cm = raw_value / CYCLES_PAR_CM;

            // Affichage
            printf("%d deg -> %d cm (Brut: %d)\n", angle_deg, distance_cm, raw_value);
        }

        // ==========================================
        // Phase 2 : Retour (180° vers 0°)
        // ==========================================
        printf("<< Scan vers la droite (180 -> 0)\n");

        for (angle_deg = 179; angle_deg >= 0; angle_deg--)
        {
            servo_cmd = (angle_deg * 255) / 180;
            IOWR_8DIRECT(SERVOMOTEUR_AVALON_0_BASE, 0, servo_cmd);

            usleep(100000); 

            raw_value = IORD(TELEMETRE_AVALON_0_BASE, 0);
            distance_cm = raw_value / CYCLES_PAR_CM;

            // Affichage 
            printf("%d deg -> %d cm (Brut: %d)\n", angle_deg, distance_cm, raw_value);
        }
    }

    return 0;
}