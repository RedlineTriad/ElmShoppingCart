using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ElmShoppingCart.Models
{
    public class Order
    {
        public Guid Id { get; set; }
        public AppUser Author { get; set; }
        public Guid AuthorId { get; set; }
        public string Product { get; set; }
        public int Amount { get; set; }
        public DateTime CreationTime { get; set; }
    }
}
