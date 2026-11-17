# SQL — opis plików

Wszystkie skrypty korzystają z **Microsoft SQL Server / T-SQL**.

| Plik | Co zawiera | Wymagane tabele |
| --- | --- | --- |
| `00_data_quality_checks.sql` | Kontrole kluczy, braków, typów, ujemnych wartości, statusów | `staging_sales`, `staging_customers`, `staging_products` |
| `01_business_analysis.sql` | Kategorie, klienci, segmenty, statusy, kupony, ranking, pierwsze zamówienia | `dbo.Sales`, `dbo.Customers`, `dbo.Products` |
| `02_powerbi_validation.sql` | KPI, zamówienia Delivered, miesięczny MoM przez `LAG`, AOV | `dbo.Sales` |

## Uwagi o przygotowaniu plików

Skrypty są uporządkowaną wersją rzeczywistych zapytań projektowych oraz zapytań walidacyjnych z raportu. W przesłanych oryginałach znajdowały się m.in. brakujące separatory zapytań oraz powtórzone fragmenty `INSERT` bez poprawnego zamknięcia. **Nie publikujemy ich jako gotowej, działającej procedury importu**, ponieważ zależą od nieudostępnionej definicji tabel, a identyfikatory źródłowe mogą mieć tekstowe prefiksy (`ORD`, `CUST`).

Skrypty w tym katalogu nie modyfikują bazy (tylko `SELECT`). Nie zostały tu uruchomione na SQL Server; przed udostępnianiem jako w pełni odtwarzalnego projektu warto wykonać końcowy test w swoim środowisku.

Dane: Jatin Khandelwal, *Indian E-Commerce Sales Analytics Dataset* (Kaggle).
