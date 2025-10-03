1. Admin approves MaliciousContract: 50,000 tokens
2. Admin realizes error, tries to reduce to 5,000 tokens
3. MaliciousContract detects tx in mempool
4. MaliciousContract frontruns with higher gas
5. attack() → transferFrom() → receive() → transferFrom() → receive() → ... (LOOP)
6. All 50,000 tokens drained recursively
7. Admin's approve(5,000) executes
8. MaliciousContract drains another 5,000 tokens
9. Total stolen: 55,000 (11x amplification)
