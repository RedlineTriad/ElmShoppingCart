using AutoMapper;
using ElmShoppingCart.Models.ViewModel;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ElmShoppingCart.Models
{
    public class AutoMapping : Profile
    {
        public AutoMapping()
        {
            CreateMap<Order, OrderViewModel>();
            CreateMap<CreateOrderViewModel, Order>();
        }
    }
}
