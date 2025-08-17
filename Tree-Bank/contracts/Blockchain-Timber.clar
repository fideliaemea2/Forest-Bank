;; Sustainable Forest Asset Tokenization Smart Contract
;; A comprehensive platform for tokenizing timber rights and forest assets,
;; enabling fractional ownership, sustainable forestry management, and transparent
;; harvest proceeds distribution based on verified sustainability metrics.

;; Contract Constants
(define-constant contract-administrator tx-sender)
(define-constant maximum-coordinate-latitude 90000000)
(define-constant minimum-coordinate-latitude (- 90000000))
(define-constant maximum-coordinate-longitude 180000000)
(define-constant minimum-coordinate-longitude (- 180000000))
(define-constant maximum-sustainability-score u100)
(define-constant minimum-reputation-score u100)
(define-constant percentage-multiplier u100)

;; Error Response Constants
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-RESOURCE-NOT-FOUND (err u101))
(define-constant ERR-RESOURCE-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-AMOUNT-SPECIFIED (err u103))
(define-constant ERR-INSUFFICIENT-TOKEN-BALANCE (err u104))
(define-constant ERR-INVALID-TIME-PERIOD (err u105))
(define-constant ERR-CONTRACT-PERIOD-EXPIRED (err u106))
(define-constant ERR-HARVEST-NOT-MATURE (err u107))
(define-constant ERR-INVALID-COORDINATE-VALUES (err u108))
(define-constant ERR-INVALID-TREE-SPECIES (err u109))
(define-constant ERR-TOKEN-TRANSFER-FAILED (err u110))
(define-constant ERR-INVALID-INPUT-PROVIDED (err u111))

;; Fungible Token Definition
(define-fungible-token sustainable-forest-token)

;; Global State Variables
(define-data-var total-forest-parcels-count uint u0)
(define-data-var platform-operations-paused bool false)
(define-data-var base-timber-token-price uint u1000000)

;; Core Data Structures
(define-map forest-parcel-registry uint {
    parcel-owner: principal,
    geographical-latitude: int,
    geographical-longitude: int,
    total-area-hectares: uint,
    primary-tree-species: (string-ascii 50),
    estimated-timber-volume: uint,
    initial-planting-date: uint,
    projected-harvest-date: uint,
    sustainability-certification: (string-ascii 100),
    total-token-supply: uint,
    remaining-available-tokens: uint,
    individual-token-price: uint,
    verification-status-confirmed: bool,
    harvest-completion-status: bool,
    metadata-uri-reference: (optional (string-ascii 256))
})

(define-map token-holder-balances { 
    token-holder: principal, 
    forest-parcel-identifier: uint 
} uint)

(define-map forest-parcel-transaction-history uint {
    transaction-buyer: principal,
    transaction-seller: principal,
    tokens-transferred-amount: uint,
    total-transaction-price: uint,
    transaction-timestamp: uint
})

(define-map harvest-verification-reports uint {
    associated-parcel-identifier: uint,
    measured-actual-volume: uint,
    completed-harvest-date: uint,
    authorized-certifier: principal,
    sustainability-rating-score: uint,
    detailed-report-uri: (string-ascii 256)
})

(define-map platform-user-profiles principal {
    user-reputation-score: uint,
    completed-transaction-count: uint,
    account-verification-status: bool,
    platform-registration-date: uint
})

(define-map authorized-certification-verifiers principal bool)

;; Query Functions for Data Retrieval
(define-read-only (retrieve-forest-parcel-details (parcel-identifier uint))
    (map-get? forest-parcel-registry parcel-identifier))

(define-read-only (retrieve-user-token-balance (account-holder principal) (parcel-identifier uint))
    (default-to u0 (map-get? token-holder-balances { 
        token-holder: account-holder, 
        forest-parcel-identifier: parcel-identifier 
    })))

(define-read-only (retrieve-total-parcels-count)
    (var-get total-forest-parcels-count))

(define-read-only (retrieve-platform-pause-status)
    (var-get platform-operations-paused))

(define-read-only (retrieve-user-profile-information (account-holder principal))
    (map-get? platform-user-profiles account-holder))

(define-read-only (retrieve-harvest-report-details (parcel-identifier uint))
    (map-get? harvest-verification-reports parcel-identifier))

(define-read-only (check-verifier-authorization-status (potential-verifier principal))
    (default-to false (map-get? authorized-certification-verifiers potential-verifier)))

(define-read-only (calculate-total-token-value (parcel-identifier uint) (token-quantity uint))
    (match (map-get? forest-parcel-registry parcel-identifier)
        parcel-information (ok (* token-quantity (get individual-token-price parcel-information)))
        ERR-RESOURCE-NOT-FOUND
    ))

(define-read-only (determine-parcel-harvest-readiness (parcel-identifier uint))
    (match (map-get? forest-parcel-registry parcel-identifier)
        parcel-information
        (let ((current-block-time (unwrap-panic (get-block-info? time (- block-height u1)))))
            (if (>= current-block-time (get projected-harvest-date parcel-information))
                (ok true)
                (ok false)
            )
        )
        ERR-RESOURCE-NOT-FOUND
    ))

;; Internal Utility Functions
(define-private (validate-geographical-coordinates (latitude-value int) (longitude-value int))
    (and 
        (>= latitude-value minimum-coordinate-latitude) 
        (<= latitude-value maximum-coordinate-latitude) 
        (>= longitude-value minimum-coordinate-longitude) 
        (<= longitude-value maximum-coordinate-longitude)))

(define-private (validate-tree-species-input (species-name (string-ascii 50)))
    (> (len species-name) u0))

(define-private (update-user-transaction-profile (account-holder principal))
    (let ((existing-profile (default-to
                { 
                    user-reputation-score: minimum-reputation-score, 
                    completed-transaction-count: u0, 
                    account-verification-status: false, 
                    platform-registration-date: (unwrap-panic (get-block-info? time (- block-height u1))) 
                }
                (map-get? platform-user-profiles account-holder))))
        (map-set platform-user-profiles account-holder (merge existing-profile {
            completed-transaction-count: (+ (get completed-transaction-count existing-profile) u1)
        }))
    ))

;; User Account Management Functions
(define-public (initialize-user-platform-profile)
    (let ((current-registration-time (unwrap-panic (get-block-info? time (- block-height u1)))))
        (begin
            (if (is-none (map-get? platform-user-profiles tx-sender))
                (map-set platform-user-profiles tx-sender {
                    user-reputation-score: minimum-reputation-score,
                    completed-transaction-count: u0,
                    account-verification-status: false,
                    platform-registration-date: current-registration-time
                })
                true
            )
            (ok true)
        )
    ))

;; Forest Parcel Registration and Management
(define-public (register-new-forest-parcel
    (geographical-latitude int)
    (geographical-longitude int)
    (total-area-hectares uint)
    (primary-tree-species (string-ascii 50))
    (estimated-timber-volume uint)
    (initial-planting-date uint)
    (projected-harvest-date uint)
    (sustainability-certification (string-ascii 100))
    (total-token-supply uint)
    (individual-token-price uint)
    (metadata-uri-reference (optional (string-ascii 256))))
    (let ((new-parcel-identifier (+ (var-get total-forest-parcels-count) u1))
          (current-registration-time (unwrap-panic (get-block-info? time (- block-height u1)))))
        
        ;; Platform and Input Validations
        (asserts! (not (var-get platform-operations-paused)) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (validate-geographical-coordinates geographical-latitude geographical-longitude) ERR-INVALID-COORDINATE-VALUES)
        (asserts! (validate-tree-species-input primary-tree-species) ERR-INVALID-TREE-SPECIES)
        (asserts! (> total-area-hectares u0) ERR-INVALID-AMOUNT-SPECIFIED)
        (asserts! (> estimated-timber-volume u0) ERR-INVALID-AMOUNT-SPECIFIED)
        (asserts! (> total-token-supply u0) ERR-INVALID-AMOUNT-SPECIFIED)
        (asserts! (> individual-token-price u0) ERR-INVALID-AMOUNT-SPECIFIED)
        (asserts! (> projected-harvest-date current-registration-time) ERR-INVALID-TIME-PERIOD)
        (asserts! (> projected-harvest-date initial-planting-date) ERR-INVALID-TIME-PERIOD)
        (asserts! (> (len sustainability-certification) u0) ERR-INVALID-INPUT-PROVIDED)
        
        ;; Validate optional metadata URI
        (if (is-some metadata-uri-reference)
            (asserts! (> (len (unwrap-panic metadata-uri-reference)) u0) ERR-INVALID-INPUT-PROVIDED)
            true
        )

        ;; Initialize user profile if needed
        (unwrap-panic (initialize-user-platform-profile))

        ;; Register the forest parcel
        (map-set forest-parcel-registry new-parcel-identifier {
            parcel-owner: tx-sender,
            geographical-latitude: geographical-latitude,
            geographical-longitude: geographical-longitude,
            total-area-hectares: total-area-hectares,
            primary-tree-species: primary-tree-species,
            estimated-timber-volume: estimated-timber-volume,
            initial-planting-date: initial-planting-date,
            projected-harvest-date: projected-harvest-date,
            sustainability-certification: sustainability-certification,
            total-token-supply: total-token-supply,
            remaining-available-tokens: total-token-supply,
            individual-token-price: individual-token-price,
            verification-status-confirmed: false,
            harvest-completion-status: false,
            metadata-uri-reference: metadata-uri-reference
        })

        ;; Assign initial token balance to parcel owner
        (map-set token-holder-balances { 
            token-holder: tx-sender, 
            forest-parcel-identifier: new-parcel-identifier 
        } total-token-supply)

        ;; Update global parcel counter
        (var-set total-forest-parcels-count new-parcel-identifier)

        (ok new-parcel-identifier)
    ))

;; Token Trading and Transfer Functions
(define-public (execute-token-purchase (parcel-identifier uint) (desired-token-quantity uint))
    (let ((parcel-information (unwrap! (map-get? forest-parcel-registry parcel-identifier) ERR-RESOURCE-NOT-FOUND))
          (total-purchase-cost (* desired-token-quantity (get individual-token-price parcel-information)))
          (current-parcel-owner (get parcel-owner parcel-information))
          (buyer-current-balance (retrieve-user-token-balance tx-sender parcel-identifier))
          (owner-current-balance (retrieve-user-token-balance current-parcel-owner parcel-identifier)))
        
        ;; Purchase Validations
        (asserts! (not (var-get platform-operations-paused)) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (> desired-token-quantity u0) ERR-INVALID-AMOUNT-SPECIFIED)
        (asserts! (<= desired-token-quantity (get remaining-available-tokens parcel-information)) ERR-INSUFFICIENT-TOKEN-BALANCE)
        (asserts! (not (is-eq tx-sender current-parcel-owner)) ERR-UNAUTHORIZED-ACCESS)

        ;; Initialize buyer profile if needed
        (unwrap-panic (initialize-user-platform-profile))

        ;; Execute STX payment transfer
        (try! (stx-transfer? total-purchase-cost tx-sender current-parcel-owner))

        ;; Update token balances
        (map-set token-holder-balances { 
            token-holder: tx-sender, 
            forest-parcel-identifier: parcel-identifier 
        } (+ buyer-current-balance desired-token-quantity))
        
        (map-set token-holder-balances { 
            token-holder: current-parcel-owner, 
            forest-parcel-identifier: parcel-identifier 
        } (- owner-current-balance desired-token-quantity))

        ;; Update parcel available tokens
        (map-set forest-parcel-registry parcel-identifier (merge parcel-information {
            remaining-available-tokens: (- (get remaining-available-tokens parcel-information) desired-token-quantity)
        }))

        ;; Record transaction in history
        (map-set forest-parcel-transaction-history parcel-identifier {
            transaction-buyer: tx-sender,
            transaction-seller: current-parcel-owner,
            tokens-transferred-amount: desired-token-quantity,
            total-transaction-price: total-purchase-cost,
            transaction-timestamp: (unwrap-panic (get-block-info? time (- block-height u1)))
        })

        ;; Update user profiles
        (update-user-transaction-profile tx-sender)
        (update-user-transaction-profile current-parcel-owner)

        (ok true)
    ))

(define-public (transfer-tokens-between-users (token-recipient principal) (parcel-identifier uint) (transfer-token-quantity uint))
    (let ((sender-current-balance (retrieve-user-token-balance tx-sender parcel-identifier))
          (recipient-current-balance (retrieve-user-token-balance token-recipient parcel-identifier)))
        
        ;; Transfer Validations
        (asserts! (not (var-get platform-operations-paused)) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (> transfer-token-quantity u0) ERR-INVALID-AMOUNT-SPECIFIED)
        (asserts! (>= sender-current-balance transfer-token-quantity) ERR-INSUFFICIENT-TOKEN-BALANCE)
        (asserts! (not (is-eq tx-sender token-recipient)) ERR-UNAUTHORIZED-ACCESS)

        ;; Execute token balance updates
        (map-set token-holder-balances { 
            token-holder: tx-sender, 
            forest-parcel-identifier: parcel-identifier 
        } (- sender-current-balance transfer-token-quantity))
        
        (map-set token-holder-balances { 
            token-holder: token-recipient, 
            forest-parcel-identifier: parcel-identifier 
        } (+ recipient-current-balance transfer-token-quantity))

        ;; Update transaction profiles
        (update-user-transaction-profile tx-sender)
        (update-user-transaction-profile token-recipient)

        (ok true)
    ))

;; Verification and Certification Functions
(define-public (confirm-parcel-verification (parcel-identifier uint))
    (let ((parcel-information (unwrap! (map-get? forest-parcel-registry parcel-identifier) ERR-RESOURCE-NOT-FOUND)))
        
        ;; Verification Authorization Check
        (asserts! (> parcel-identifier u0) ERR-INVALID-INPUT-PROVIDED)
        (asserts! (check-verifier-authorization-status tx-sender) ERR-UNAUTHORIZED-ACCESS)

        ;; Update parcel verification status
        (map-set forest-parcel-registry parcel-identifier (merge parcel-information {
            verification-status-confirmed: true
        }))

        (ok true)
    ))

(define-public (submit-official-harvest-report
    (parcel-identifier uint)
    (measured-actual-volume uint)
    (sustainability-rating-score uint)
    (detailed-report-uri (string-ascii 256)))
    (let ((parcel-information (unwrap! (map-get? forest-parcel-registry parcel-identifier) ERR-RESOURCE-NOT-FOUND))
          (current-report-time (unwrap-panic (get-block-info? time (- block-height u1)))))
        
        ;; Harvest Report Validations
        (asserts! (check-verifier-authorization-status tx-sender) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (>= current-report-time (get projected-harvest-date parcel-information)) ERR-HARVEST-NOT-MATURE)
        (asserts! (> measured-actual-volume u0) ERR-INVALID-AMOUNT-SPECIFIED)
        (asserts! (<= sustainability-rating-score maximum-sustainability-score) ERR-INVALID-AMOUNT-SPECIFIED)
        (asserts! (> (len detailed-report-uri) u0) ERR-INVALID-INPUT-PROVIDED)

        ;; Create comprehensive harvest report
        (map-set harvest-verification-reports parcel-identifier {
            associated-parcel-identifier: parcel-identifier,
            measured-actual-volume: measured-actual-volume,
            completed-harvest-date: current-report-time,
            authorized-certifier: tx-sender,
            sustainability-rating-score: sustainability-rating-score,
            detailed-report-uri: detailed-report-uri
        })

        ;; Mark parcel as successfully harvested
        (map-set forest-parcel-registry parcel-identifier (merge parcel-information {
            harvest-completion-status: true
        }))

        (ok true)
    ))

;; Revenue Distribution Functions
(define-public (claim-proportional-harvest-proceeds (parcel-identifier uint))
    (let ((parcel-information (unwrap! (map-get? forest-parcel-registry parcel-identifier) ERR-RESOURCE-NOT-FOUND))
          (harvest-report-data (unwrap! (map-get? harvest-verification-reports parcel-identifier) ERR-RESOURCE-NOT-FOUND))
          (claimant-token-balance (retrieve-user-token-balance tx-sender parcel-identifier))
          (parcel-total-supply (get total-token-supply parcel-information)))
        
        ;; Claim Eligibility Validations
        (asserts! (get harvest-completion-status parcel-information) ERR-HARVEST-NOT-MATURE)
        (asserts! (> claimant-token-balance u0) ERR-INSUFFICIENT-TOKEN-BALANCE)

        ;; Calculate proportional harvest proceeds
        (let ((claimant-ownership-share (* claimant-token-balance percentage-multiplier))
              (total-ownership-shares (* parcel-total-supply percentage-multiplier))
              (ownership-percentage (/ claimant-ownership-share total-ownership-shares))
              (total-harvest-proceeds (* (get measured-actual-volume harvest-report-data) (var-get base-timber-token-price)))
              (claimant-entitled-proceeds (/ (* total-harvest-proceeds ownership-percentage) percentage-multiplier)))

            ;; Transfer calculated proceeds to claimant
            (try! (stx-transfer? claimant-entitled-proceeds (as-contract tx-sender) tx-sender))

            ;; Consume tokens after successful claim
            (map-set token-holder-balances { 
                token-holder: tx-sender, 
                forest-parcel-identifier: parcel-identifier 
            } u0)

            (ok claimant-entitled-proceeds)
        )
    ))

;; Administrative Management Functions
(define-public (authorize-new-verifier (new-verifier-principal principal))
    (begin
        (asserts! (is-eq tx-sender contract-administrator) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (not (is-eq new-verifier-principal tx-sender)) ERR-INVALID-INPUT-PROVIDED)
        (map-set authorized-certification-verifiers new-verifier-principal true)
        (ok true)
    ))

(define-public (revoke-verifier-authorization (target-verifier-principal principal))
    (begin
        (asserts! (is-eq tx-sender contract-administrator) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (not (is-eq target-verifier-principal tx-sender)) ERR-INVALID-INPUT-PROVIDED)
        (map-set authorized-certification-verifiers target-verifier-principal false)
        (ok true)
    ))

(define-public (activate-platform-pause)
    (begin
        (asserts! (is-eq tx-sender contract-administrator) ERR-UNAUTHORIZED-ACCESS)
        (var-set platform-operations-paused true)
        (ok true)
    ))

(define-public (deactivate-platform-pause)
    (begin
        (asserts! (is-eq tx-sender contract-administrator) ERR-UNAUTHORIZED-ACCESS)
        (var-set platform-operations-paused false)
        (ok true)
    ))

(define-public (update-base-timber-pricing (new-pricing-value uint))
    (begin
        (asserts! (is-eq tx-sender contract-administrator) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (> new-pricing-value u0) ERR-INVALID-AMOUNT-SPECIFIED)
        (var-set base-timber-token-price new-pricing-value)
        (ok true)
    ))

;; Parcel Metadata Management
(define-public (update-parcel-metadata-uri (parcel-identifier uint) (updated-metadata-uri (string-ascii 256)))
    (let ((parcel-information (unwrap! (map-get? forest-parcel-registry parcel-identifier) ERR-RESOURCE-NOT-FOUND)))
        (asserts! (is-eq tx-sender (get parcel-owner parcel-information)) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (> (len updated-metadata-uri) u0) ERR-INVALID-INPUT-PROVIDED)

        (map-set forest-parcel-registry parcel-identifier (merge parcel-information {
            metadata-uri-reference: (some updated-metadata-uri)
        }))

        (ok true)
    ))