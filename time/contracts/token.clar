;; Token Contract
;; Implements a basic fungible token with minting, burning, transfers, approvals, and pause/unpause functionality

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-INSUFFICIENT-ALLOWANCE (err u103))
(define-constant ERR-CONTRACT-PAUSED (err u104))

(define-data-var contract-owner principal tx-sender)
(define-data-var total-supply uint u0)
(define-data-var is-paused bool false)
(define-map balances { owner: principal } uint)
(define-map allowances { owner: principal, spender: principal } uint)

;; Validation helpers
(define-private (is-valid-principal (address principal))
    (and 
        (is-ok (principal-destruct? address))
        (not (is-eq address tx-sender))))

(define-private (is-contract-owner)
    (is-eq tx-sender (var-get contract-owner)))

;; Admin functions
(define-public (pause)
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (var-set is-paused true)
        (ok true)))

(define-public (unpause)
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (var-set is-paused false)
        (ok true)))

;; Token operations
(define-public (mint (amount uint) (recipient principal))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (is-valid-principal recipient) ERR-NOT-AUTHORIZED)
        (var-set total-supply (+ (var-get total-supply) amount))
        (map-set balances { owner: recipient } (+ (default-to u0 (map-get? balances { owner: recipient })) amount))
        (ok true)))

(define-public (burn (amount uint))
    (let ((balance (default-to u0 (map-get? balances { owner: tx-sender }))))
        (begin
            (asserts! (>= balance amount) ERR-INSUFFICIENT-BALANCE)
            (var-set total-supply (- (var-get total-supply) amount))
            (map-set balances { owner: tx-sender } (- balance amount))
            (ok true))))

(define-public (transfer (amount uint) (recipient principal))
    (let ((balance (default-to u0 (map-get? balances { owner: tx-sender }))))
        (begin
            (asserts! (not (var-get is-paused)) ERR-CONTRACT-PAUSED)
            (asserts! (>= balance amount) ERR-INSUFFICIENT-BALANCE)
            (asserts! (is-valid-principal recipient) ERR-NOT-AUTHORIZED)
            (map-set balances { owner: tx-sender } (- balance amount))
            (map-set balances { owner: recipient } (+ (default-to u0 (map-get? balances { owner: recipient })) amount))
            (ok true))))

(define-public (approve (spender principal) (amount uint))
    (begin
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (is-valid-principal spender) ERR-NOT-AUTHORIZED)
        (map-set allowances { owner: tx-sender, spender: spender } amount)
        (ok true)))

(define-public (transfer-from (owner principal) (recipient principal) (amount uint))
    (let ((allowance (default-to u0 (map-get? allowances { owner: owner, spender: tx-sender })))
          (balance (default-to u0 (map-get? balances { owner: owner }))))
        (begin
            (asserts! (not (var-get is-paused)) ERR-CONTRACT-PAUSED)
            (asserts! (>= allowance amount) ERR-INSUFFICIENT-ALLOWANCE)
            (asserts! (>= balance amount) ERR-INSUFFICIENT-BALANCE)
            (asserts! (and (is-valid-principal owner) (is-valid-principal recipient)) ERR-NOT-AUTHORIZED)
            (map-set allowances { owner: owner, spender: tx-sender } (- allowance amount))
            (map-set balances { owner: owner } (- balance amount))
            (map-set balances { owner: recipient } (+ (default-to u0 (map-get? balances { owner: recipient })) amount))
            (ok true))))

;; Read-only functions
(define-read-only (get-balance (owner principal))
    (ok (default-to u0 (map-get? balances { owner: owner }))))

(define-read-only (get-allowance (owner principal) (spender principal))
    (ok (default-to u0 (map-get? allowances { owner: owner, spender: spender }))))

(define-read-only (get-paused-state)
    (ok (var-get is-paused)))