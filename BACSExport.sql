#StartDate = TEXT;
    SELECT
        '01/01/2013' AS Value
§

#EndDate = TEXT;
    SELECT
        DATE_FORMAT(NOW(), '%d/%m/%Y') AS Value
§

#Status = LIST;;
    SELECT
        DISTINCT si.Status AS ID,
        si.Status AS Label
    FROM
        `specialist_invoice` AS si
    ORDER BY
        Label
§

SELECT
    sp.SortCode AS 'Sort Code',
    sp.AccountName AS 'Account Name',
    sp.AccountNumber AS 'Account Number',
    ROUND(
        SUM(sil.Price)
        * IF(
            si.VAT = 'Yes',
            1 + si.VATRate,
            1
        )
        * CurrencyRate(si.Currency, si.CreationDate),
        2
    ) AS 'GBP Equivalent ',
    CASE sil.LineType
        WHEN 'REFERRAL'
            THEN CONCAT(si.ID, ' ', 'REFERRAL')
        WHEN 'CONSULTATION'
            THEN (
                SELECT
                    CONCAT(
                        si.ID,
                        ' ',
                        s_p.ProjectCode,
                        '/',
                        IF(s_psel.ExpertNumber IS NULL,
                            '1',
                            s_psel.ExpertNumber
                        )
                    )
                FROM
                    project_consultation AS s_pcon
                    LEFT JOIN project_selection AS s_psel ON s_psel.ID = s_pcon.ProjectSelectionID
                    LEFT JOIN projects AS s_p ON s_p.ProjectID = s_psel.ProjectID
                WHERE
                    s_pcon.ID = sil.ReferenceID
            )
        ELSE
            CONCAT(si.ID, ' ', sil.LineType)
    END AS 'Payment Reference',
    99 AS 'BACS Code'
FROM
    `specialist_invoice` AS si
    LEFT JOIN `specialist_invoicelines` AS sil ON sil.InvoiceID = si.ID
    LEFT JOIN `experts` AS ex ON ex.ID = si.SpecialistID
    LEFT JOIN `specialist_payment` AS sp ON sp.ID = ex.SelectedPaymentID
WHERE
    si.PaymentType = 'UK'
    {?Status}AND si.Status = '{Status}'{/?}
    {?StartDate}AND si.CreationDate >= STR_TO_DATE('{StartDate}', '%d/%m/%Y'){/?}
    {?EndDate}AND si.CreationDate < STR_TO_DATE('{EndDate}', '%d/%m/%Y') + INTERVAL 1 DAY{/?}
GROUP BY
    si.ID
ORDER BY
    si.CreationDate DESC