#include <library.h>
#include <print.h>
#include <platform.h>
#include <memory.h>

#include "kernel.h"

u1 process_count = 0;
u2 next_process_id = 1;

bool scheduler_enabled = true;
char * panic_message = 0;

void scheduler() {
    process_index = 0;
    thread_index = 0;
    while (true) {
        bool next_proc = false;
        if (scheduler_enabled && process_count) {
            process_t * p = &processes[process_index];
            if (p->thread_count) {
                thread_t * t = &p->threads[thread_index];
                if (t->valid) {
                    context_switch(&schedulerc, t->context);
                }
                thread_index = (thread_index + 1) % THREAD_COUNT_MAX;
                if (!thread_index) {
                    next_proc = true;
                }
            } else {
                next_proc = true;
            }
            if (next_proc) {
                process_index = (process_index + 1) % PROCESS_COUNT_MAX;
                thread_index = 0;
            }
        }
    }
}

extern void * setup_process(u4 eip, u4 esp);
extern void usermode();

void make_proc(char value) {

}

void kernel_main() {

    //print_dragon();

    //memory_init();
    //print_char('\n');
    
    /*
    allocate_vmem(0, 2 * FRAME_SIZE);
    tss.esp0 = 2 * FRAME_SIZE - 1;

    const u4 start = 0xc0101aca;
    memcpy(0, start, 0xc0101adf - start);
    usermode(0, 0xFFF);

    asm(
        "movl $99, %%eax\n\t" // print_char
        "movl $0x2B, %%ebx\n\t" // '+'
        "int $100\n\t"
        "movl $0, %%eax\n\t"
        "jmp %%eax\n\t"
        ::: "%eax", "%ebx"
    );
    */

    /*
    asm (
        "movl $66, %eax\n\t"
        "int $100\n\t"
    );
    */
    /*
    asm ("movb $0x90, (0)");  // nop
    asm ("movb $0xeb, (1)");  // jmp to prev instruction
    asm ("movb $0xfd, (2)");
    */
    /*
    asm ("movb $0xb8, (0)"); // mov $0x42,%eax
    asm ("movb $0x42, (1)");
    asm ("movb $0x00, (2)");
    asm ("movb $0x00, (3)");
    asm ("movb $0x00, (4)");
    asm ("movb $0xcd, (5)"); // int $0x64
    asm ("movb $0x64, (6)");
    breakpoint();
    usermode();
    */

    /*
    allocate_vmem(0, KiB(10));

    parentp.id = 0;
    parentp.running = 1;
    parentp.stack = KiB(5) - 1;
    parentp.context = setup_process((u4) parent, parentp.stack);

    childp.id = 1;
    childp.running = 0;
    childp.stack = KiB(10) - 1;
    childp.context = setup_process((u4) child, childp.stack);

    currentp = &parentp;
    scheduler();
    */

    print_string("Done\n");
}

