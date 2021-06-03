class CompanyFactorName < ApplicationRecord
    
    def  self.insert_factors(cid,sid)
        self.where(company_id: cid, snapshot_id: sid).delete_all
        Factor.all.each do |f|
            self.create(factor_name: f.name, company_id:cid, snapshot_id: sid)
        end
    end
end
