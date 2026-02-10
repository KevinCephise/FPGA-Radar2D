#include <stdio.h>
#include <unistd.h> 
#include "system.h" 
#include "altera_avalon_pio_regs.h" 

// Table de décodage pour l'afficheur 7 segments (0 à 9)
// Bit 0 = Segment A, Bit 6 = Segment G
const int table_7seg[10] = {
    0x3F, // 0
    0x06, // 1
    0x5B, // 2
    0x4F, // 3
    0x66, // 4
    0x6D, // 5
    0x7D, // 6
    0x07, // 7
    0x7F, // 8
    0x6F  // 9
};

int main()
{
    printf("Demarrage du Telemetre Ultrason...\n");

    int distance = 0;
    int unites, dizaines, centaines;
    int affichage_hex;

    while(1)
    {
        distance = IORD(TELEMETRE_AVALON_0_BASE, 0) / (2900 * 2); // On divise par 2900 car on récupère le nombre de coup de clock
        														  // On divise encore par 2 puisque la clock de notre NIOS 2 est de 100MHz (soit 2 * 50MHz)

        printf("Distance : %d cm\n", distance);

        if (distance > 999) distance = 999; // Saturation pour l'affichage

        unites = distance % 10;
        dizaines = (distance / 10) % 10;
        centaines = (distance / 100) % 10;

        // On construit le mot de 32 bits pour les afficheurs HEX3-HEX0
        // HEX0 (bits 0-7), HEX1 (bits 8-15), HEX2 (bits 16-23)
        affichage_hex = table_7seg[unites] |
                       (table_7seg[dizaines] << 8) |
                       (table_7seg[centaines] << 16);


        IOWR(HEX3_HEX0_BASE, 0, affichage_hex);

        usleep(100000);
    }

    return 0;
}
