using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ElmShoppingCart.Models.ViewModel
{
    public class OrderViewModel
    {
        public Guid Id { get; set; }
        public Guid AuthorId { get; set; }
        public string Product { get; set; }
        public int Amount { get; set; }
        public DateTime CreationTime { get; set; }
    }
}
