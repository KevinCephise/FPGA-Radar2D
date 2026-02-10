#include <stdio.h>
#include "unistd.h"
#include "system.h"
#include "io.h"
#include "altera_avalon_pio_regs.h" // Nécessaire pour les macros des périphériques standards

int main()
{
    printf("Test Servomoteur et Switchs...\n");

    int switch_value = 0;
    int servo_command = 0;

    while(1)
    {
        switch_value = IORD(SLIDER_SWITCHES_BASE, 0);

        // On prend les 8 premiers switchs (SW0 à SW7) en appliquant un masque 0xFF.
        servo_command = switch_value & 0xFF;

        IOWR(SERVOMOTEUR_AVALON_0_BASE, 0, servo_command);

        // Affichage de debug 
        printf("Switch: %d -> Servo: %d\n", switch_value, servo_command);

        usleep(20000); // 20ms
    }

    return 0;
}
