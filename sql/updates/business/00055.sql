DROP VIEW product_current;

CREATE OR REPLACE VIEW product_current AS
SELECT
       p.id AS id, 
       pd.id AS detailid,
       pd.product,
       account,
       shortname,
       description,
       price_buy,
       price_sell,
       margin,
       markup,
       is_available,
       is_offered,
       pd.updated,
       pd.authuser,
       pd.clientip, 
       MIN(pt.tax) AS tax
FROM product p
INNER JOIN productdetail pd ON p.id = pd.product
INNER JOIN product_tax pt ON p.id = pt.product
WHERE pd.id IN (
        SELECT MAX(id)
        FROM productdetail
        GROUP BY product
)
GROUP BY
       p.id,
       pd.id,
       account,
       shortname,       
       description,     
       price_buy,       
       price_sell,      
       margin,
       markup,
       is_available,    
       is_offered,      
       pd.updated,
       pd.authuser,
       pd.clientip
;

