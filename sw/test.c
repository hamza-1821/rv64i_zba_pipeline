/**
 * Simplified RV64I + Zba Test Program
 * 
 */

#define DATA_BASE 0x1000
#define RESULT_BASE 0x1100

int main() {
    // Direct register-based operations to test core functionality
    
    volatile long *results = (volatile long *)RESULT_BASE;
    
    long a = 20;
    long b = 20;
    
    // Store test parameters in memory for testbench to read (at safe location)
    volatile long *test_params = (volatile long *)0x0F00;  // Store at 0x0F00 and 0x0F08
    *(test_params + 0) = a;  // Store a at 0x0F00
    *(test_params + 1) = b;  // Store b at 0x0F08
    
    // Store directly to prevent compiler optimization
    *(results + 0) = a + b;               // Test 1: ADD = a + b
    *(results + 1) = a - b;               // Test 2: SUB = a - b
    
    // Test 3: Memory Store/Load
    volatile long *mem = (volatile long *)0x1000;
    *mem = 123;
    *(results + 2) = *mem;                // Load and store = 123
    
    *(results + 3) = a & b;               // Test 4: AND = a & b
    *(results + 4) = a | b;               // Test 5: OR = a | b
    *(results + 5) = a ^ b;               // Test 6: XOR = a ^ b
    *(results + 6) = a << 2;              // Test 7: SLL = a << 2
    *(results + 7) = a >> 2;              // Test 8: SRL = a >> 2
    
    long sum = a + b;
    *(results + 8) = (sum == (a + b)) ? 1 : 0;  // Test 9: BEQ (sum == a+b)
    
    long diff = a - b;
    *(results + 9) = (diff < sum) ? 1 : 0;  // Test 10: BLT (diff < sum)
    
    *(results + 10) = a + (b << 2);       // Test 11: SH2ADD = a + (b << 2)
    *(results + 11) = a + (b << 3);       // Test 12: SH3ADD = a + (b << 3)
    
    // Signal completion
    *(results + 12) = 0xDEADBEEF;
    
    // Infinite loop
    while(1);
    
    return 0;
}





